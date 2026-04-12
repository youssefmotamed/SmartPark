// Service handling gate entry and exit scan logic for guards.
package com.smartpark.service;

import com.smartpark.dto.request.GateScanRequest;
import com.smartpark.dto.response.GateEntryResponse;
import com.smartpark.model.Reservation;
import com.smartpark.model.User;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Handles QR code scanning at the entry and exit gates.
 * Invalid scan scenarios (not found, wrong status, expired) return {@code valid=false}
 * with a human-readable reason rather than throwing exceptions.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class GateService {

    private static final Logger log = LoggerFactory.getLogger(GateService.class);

    private final ReservationRepository reservationRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final UserRepository userRepository;

    /**
     * Processes a QR code scan at the entry gate.
     * On success, transitions the reservation to ENTERED and clears its expiry timer.
     *
     * @param guardId the ID of the guard performing the scan
     * @param request the scan request containing the QR code data
     * @return a response indicating whether the scan was accepted, with relevant details
     */
    public GateEntryResponse scanEntry(Long guardId, GateScanRequest request) {
        // 1. Find reservation by QR code
        Optional<Reservation> optional = reservationRepository.findByQrCodeData(request.getQrCodeData());
        if (optional.isEmpty()) {
            return GateEntryResponse.builder()
                    .valid(false)
                    .reason("QR code not found")
                    .build();
        }

        Reservation reservation = optional.get();

        // 2. Status must be ACTIVE
        if (reservation.getStatus() != ReservationStatus.ACTIVE) {
            return GateEntryResponse.builder()
                    .valid(false)
                    .reason("Reservation is " + reservation.getStatus().toString().toLowerCase() + " (expected ACTIVE)")
                    .build();
        }

        // 3. Check expiry
        if (reservation.getExpiresAt() != null && reservation.getExpiresAt().isBefore(LocalDateTime.now())) {
            return GateEntryResponse.builder()
                    .valid(false)
                    .reason("Reservation has expired")
                    .build();
        }

        // 4. Transition to ENTERED
        User guard = userRepository.getReferenceById(guardId);
        reservation.setStatus(ReservationStatus.ENTERED);
        reservation.setEntryScannedAt(LocalDateTime.now());
        reservation.setEntryGuard(guard);
        reservation.setExpiresAt(null); // post-entry: reservation never expires
        reservationRepository.save(reservation);

        // 5. Collect registered plate numbers for this badge
        Long badgeId = reservation.getBadge().getId();
        List<String> plates = badgeCarRepository.findByBadgeId(badgeId)
                .stream()
                .map(car -> car.getPlateNumber())
                .toList();

        // 6. Get badge creator's full name
        String studentName = reservation.getBadge().getCreatedByUser().getFullName();

        // 7. Badge type
        String badgeType = reservation.getBadge().getBadgeType().toString();

        log.info("Gate entry scan: reservation {} entered by guard {}", reservation.getId(), guardId);

        return GateEntryResponse.builder()
                .valid(true)
                .spotLabel(reservation.getSpot().getSpotLabel())
                .studentName(studentName)
                .badgeType(badgeType)
                .registeredPlates(plates)
                .build();
    }
}