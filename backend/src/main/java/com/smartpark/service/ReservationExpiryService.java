// Scheduled service that expires ACTIVE reservations whose 15-minute pre-entry window has passed.
package com.smartpark.service;

import com.smartpark.model.Notification;
import com.smartpark.model.Reservation;
import com.smartpark.model.Spot;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.repository.NotificationRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.SpotRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Polls for ACTIVE reservations that have passed their expiry time and transitions
 * them to EXPIRED, freeing their spots and notifying the badge owner.
 *
 * <p>Runs 60 seconds after each execution finishes (fixedDelay) to avoid overlapping
 * runs if a batch takes longer than expected.</p>
 */
@Service
@RequiredArgsConstructor
public class ReservationExpiryService {

    private static final Logger log = LoggerFactory.getLogger(ReservationExpiryService.class);

    private final ReservationRepository reservationRepository;
    private final SpotRepository spotRepository;
    private final NotificationRepository notificationRepository;

    /**
     * Finds all ACTIVE reservations whose {@code expiresAt} is before the current time,
     * marks them EXPIRED, releases their spots back to AVAILABLE, and sends an
     * in-app notification to the badge creator.
     *
     * <p>Only ACTIVE reservations are touched — ENTERED reservations are never expired.</p>
     */
    @Scheduled(fixedDelay = 60000)
    @Transactional
    public void expireReservations() {
        List<Reservation> expired = reservationRepository.findExpiredReservations(LocalDateTime.now());

        if (expired.isEmpty()) {
            return;
        }

        for (Reservation reservation : expired) {
            Spot spot = reservation.getSpot();

            reservation.setStatus(ReservationStatus.EXPIRED);

            spot.setStatus(SpotStatus.AVAILABLE);
            spot.setStatusUpdatedAt(LocalDateTime.now());
            spotRepository.save(spot);

            Notification notification = Notification.builder()
                    .user(reservation.getBadge().getCreatedByUser())
                    .notificationType(NotificationType.RESERVATION_EXPIRED)
                    .title("Reservation Expired")
                    .message("Your reservation for spot " + spot.getSpotLabel() + " has expired.")
                    .isRead(false)
                    .build();
            notificationRepository.save(notification);

            reservationRepository.save(reservation);
        }

        log.info("Expired {} reservations", expired.size());
    }
}