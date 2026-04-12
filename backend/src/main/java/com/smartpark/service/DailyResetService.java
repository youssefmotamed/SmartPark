// Scheduled service that resets all active parking state at 8 PM each day.
// Expires ACTIVE reservations, completes ENTERED reservations, and closes open guest parking sessions.
package com.smartpark.service;

import com.smartpark.model.GuestParking;
import com.smartpark.model.Reservation;
import com.smartpark.model.Spot;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.repository.GuestParkingRepository;
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
 * Performs the nightly campus reset at 8 PM.
 *
 * <p>Clears all in-flight parking state so the next day starts clean:
 * <ul>
 *   <li>ACTIVE reservations → EXPIRED, their spots → AVAILABLE</li>
 *   <li>ENTERED reservations → COMPLETED, their spots → AVAILABLE</li>
 *   <li>ACTIVE guest-parking sessions → COMPLETED</li>
 * </ul>
 *
 * <p>Each record is processed independently; a failure on one record is logged
 * as an error but does not abort the rest of the reset.
 */
@Service
@RequiredArgsConstructor
public class DailyResetService {

    private static final Logger log = LoggerFactory.getLogger(DailyResetService.class);

    private final ReservationRepository reservationRepository;
    private final SpotRepository spotRepository;
    private final GuestParkingRepository guestParkingRepository;

    /**
     * Runs every day at 20:00 (8 PM) server time.
     * Expires ACTIVE reservations, completes ENTERED reservations,
     * and closes any still-open guest parking sessions.
     */
    @Transactional
    @Scheduled(cron = "0 0 20 * * *")
    public void performDailyReset() {
        log.info("Daily reset started");

        int expiredCount = expireActiveReservations();
        int completedCount = completeEnteredReservations();
        int guestClosedCount = closeActiveGuestParking();

        log.info("Daily reset complete — expired: {}, completed: {}, guest parking closed: {}",
                expiredCount, completedCount, guestClosedCount);
    }

    private int expireActiveReservations() {
        List<Reservation> activeReservations = reservationRepository.findByStatusWithSpot(ReservationStatus.ACTIVE);
        int count = 0;
        for (Reservation reservation : activeReservations) {
            try {
                Spot spot = reservation.getSpot();
                spot.setStatus(SpotStatus.AVAILABLE);
                spot.setStatusUpdatedAt(LocalDateTime.now());
                spotRepository.save(spot);

                reservation.setStatus(ReservationStatus.EXPIRED);
                reservationRepository.save(reservation);

                count++;
            } catch (Exception e) {
                log.error("Failed to expire reservation {} during daily reset", reservation.getId(), e);
            }
        }
        return count;
    }

    private int completeEnteredReservations() {
        List<Reservation> enteredReservations = reservationRepository.findByStatusWithSpot(ReservationStatus.ENTERED);
        int count = 0;
        for (Reservation reservation : enteredReservations) {
            try {
                Spot spot = reservation.getSpot();
                spot.setStatus(SpotStatus.AVAILABLE);
                spot.setStatusUpdatedAt(LocalDateTime.now());
                spotRepository.save(spot);

                reservation.setStatus(ReservationStatus.COMPLETED);
                reservationRepository.save(reservation);

                count++;
            } catch (Exception e) {
                log.error("Failed to complete entered reservation {} during daily reset", reservation.getId(), e);
            }
        }
        return count;
    }

    private int closeActiveGuestParking() {
        List<GuestParking> activeSessions = guestParkingRepository.findByStatus("ACTIVE");
        int count = 0;
        for (GuestParking guestParking : activeSessions) {
            try {
                guestParking.setStatus("COMPLETED");
                guestParking.setCompletedAt(LocalDateTime.now());
                guestParkingRepository.save(guestParking);

                count++;
            } catch (Exception e) {
                log.error("Failed to close guest parking session {} during daily reset", guestParking.getId(), e);
            }
        }
        return count;
    }
}