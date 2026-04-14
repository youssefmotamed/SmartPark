// Handles incoming camera spot-status updates, departure buffering, and contradiction detection.
package com.smartpark.service;

import com.smartpark.dto.request.CameraSpotStatusRequest;
import com.smartpark.dto.response.CameraUpdateResponse;
import com.smartpark.model.Notification;
import com.smartpark.model.Spot;
import com.smartpark.model.User;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.model.enums.UserRole;
import com.smartpark.repository.NotificationRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Business logic for the camera spot-status endpoint.
 *
 * <p>The camera processor posts occupancy readings every 10 seconds.
 * This service applies a departure buffer (6 consecutive empty readings ≙ 60 s)
 * before marking a spot as AVAILABLE, and raises guard notifications when a car
 * is detected in a spot that has no active reservation (contradiction).
 *
 * <p>The in-memory {@code emptyReadingCount} map is reset on server restart — acceptable for MVP.
 */
@Service
@RequiredArgsConstructor
public class CameraService {

    private static final Logger log = LoggerFactory.getLogger(CameraService.class);

    /** Number of consecutive empty readings required before confirming a departure (~60 s). */
    private static final int DEPARTURE_BUFFER_THRESHOLD = 6;

    private final SpotRepository spotRepository;
    private final ReservationRepository reservationRepository;
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    /**
     * Tracks how many consecutive empty readings each spot has received.
     * Key: spot label (e.g. "A1"). Reset to 0 whenever an occupied reading arrives.
     */
    private final Map<String, Integer> emptyReadingCount = new ConcurrentHashMap<>();

    /**
     * Processes a batch of spot-occupancy readings from the camera processor.
     *
     * @param request the payload containing the timestamp and per-spot updates
     * @return a summary of spots updated, contradictions detected, and notifications sent
     */
    @Transactional
    public CameraUpdateResponse processSpotStatuses(CameraSpotStatusRequest request) {
        int spotsUpdated = 0;
        int contradictionsDetected = 0;
        int notificationsSent = 0;

        for (CameraSpotStatusRequest.SpotStatusUpdate update : request.getSpots()) {
            String label = update.getSpotLabel();

            Optional<Spot> spotOpt = spotRepository.findBySpotLabel(label);
            if (spotOpt.isEmpty()) {
                log.warn("Camera update references unknown spot label '{}' — skipping", label);
                continue;
            }
            Spot spot = spotOpt.get();

            if (update.isOccupied()) {
                // --- Car detected in this spot ---
                emptyReadingCount.put(label, 0);

                boolean hasReservation = reservationRepository
                        .findBySpotIdAndStatusIn(spot.getId(),
                                List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED))
                        .isPresent();

                if (hasReservation) {
                    // Legitimate occupancy: promote RESERVED → OCCUPIED if needed
                    if (spot.getStatus() == SpotStatus.RESERVED || spot.getStatus() == SpotStatus.OCCUPIED) {
                        spot.setStatus(SpotStatus.OCCUPIED);
                        spot.setStatusUpdatedAt(LocalDateTime.now());
                        spotRepository.save(spot);
                        spotsUpdated++;
                    }
                } else {
                    // No reservation — determine whether this is a new contradiction
                    if (spot.getStatus() == SpotStatus.AVAILABLE) {
                        // Fresh contradiction: spot was available but now has an unregistered car
                        int sentCount = notifyAllGuards(label);
                        contradictionsDetected++;
                        notificationsSent += sentCount;
                    }
                    // If spot is already OCCUPIED with no reservation, contradiction was already
                    // reported in a prior cycle — do nothing to avoid duplicate alerts.
                }

            } else {
                // --- Spot appears empty ---

                if (spot.getStatus() == SpotStatus.AVAILABLE) {
                    // Already available — nothing to do
                    emptyReadingCount.put(label, 0);
                    continue;
                }

                if (spot.getStatus() == SpotStatus.RESERVED) {
                    // Car hasn't arrived yet; reservation is still active — do not clear
                    emptyReadingCount.put(label, 0);
                    continue;
                }

                if (spot.getStatus() == SpotStatus.OCCUPIED) {
                    int count = emptyReadingCount.merge(label, 1, Integer::sum);

                    if (count >= DEPARTURE_BUFFER_THRESHOLD) {
                        spot.setStatus(SpotStatus.AVAILABLE);
                        spot.setStatusUpdatedAt(LocalDateTime.now());
                        spotRepository.save(spot);
                        emptyReadingCount.put(label, 0);
                        spotsUpdated++;
                        log.info("Spot {} departure confirmed after 60s buffer", label);
                    }
                }
            }
        }

        log.info("Camera update processed: {} spots updated, {} contradictions, {} notifications",
                spotsUpdated, contradictionsDetected, notificationsSent);

        return new CameraUpdateResponse(spotsUpdated, contradictionsDetected, notificationsSent);
    }

    /**
     * Creates a SPOT_CONTRADICTION notification for every guard in the system.
     *
     * @param spotLabel the label of the spot where the contradiction was detected
     * @return the number of notifications created
     */
    private int notifyAllGuards(String spotLabel) {
        List<User> guards = userRepository.findByRole(UserRole.GUARD);
        for (User guard : guards) {
            Notification notification = Notification.builder()
                    .user(guard)
                    .notificationType(NotificationType.SPOT_CONTRADICTION)
                    .title("Unauthorized car detected")
                    .message("Spot " + spotLabel + " is occupied but has no active reservation. Please investigate.")
                    .isRead(false)
                    .build();
            notificationRepository.save(notification);
        }
        return guards.size();
    }
}