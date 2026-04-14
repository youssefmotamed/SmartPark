// Scheduled service that sends 5-minute expiry warnings to all accepted badge members.
package com.smartpark.service;

import com.smartpark.model.BadgeMember;
import com.smartpark.model.Reservation;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.ReservationRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Polls once per minute for ACTIVE reservations expiring within the next ~5 minutes
 * and sends an in-app warning to every accepted member of the badge that holds the
 * reservation.
 *
 * <p>The warning window is [now+4:30, now+5:30] rather than an exact 5:00 check so
 * that slight scheduler drift (early or late firing) cannot cause a warning to be
 * silently skipped.</p>
 *
 * <p>Only ACTIVE reservations are targeted. ENTERED reservations have a null
 * {@code expiresAt} and never expire, so they are never matched.</p>
 */
@Service
@RequiredArgsConstructor
public class FiveMinuteWarningService {

    private static final Logger log = LoggerFactory.getLogger(FiveMinuteWarningService.class);

    private final ReservationRepository reservationRepository;
    private final NotificationService notificationService;
    private final BadgeMemberRepository badgeMemberRepository;

    /**
     * Finds all ACTIVE reservations whose {@code expiresAt} falls inside the window
     * [now+4:30, now+5:30], then notifies every accepted member of the owning badge.
     *
     * <p>Runs 60 seconds after each execution completes (fixedDelay) to avoid
     * overlapping runs when the batch takes longer than expected.</p>
     */
    @Scheduled(fixedDelay = 60000)
    @Transactional
    public void sendFiveMinuteWarnings() {
        LocalDateTime windowStart = LocalDateTime.now().plusMinutes(4).plusSeconds(30);
        LocalDateTime windowEnd   = LocalDateTime.now().plusMinutes(5).plusSeconds(30);

        List<Reservation> reservations = reservationRepository
                .findByStatusAndExpiresAtBetween(ReservationStatus.ACTIVE, windowStart, windowEnd);

        if (reservations.isEmpty()) {
            return;
        }

        for (Reservation reservation : reservations) {
            String spotLabel = reservation.getSpot().getSpotLabel();
            Long badgeId = reservation.getBadge().getId();

            List<BadgeMember> members = badgeMemberRepository
                    .findByBadgeIdAndStatus(badgeId, BadgeMemberStatus.ACCEPTED);

            for (BadgeMember member : members) {
                notificationService.createNotificationForUser(
                        member.getUser(),
                        NotificationType.FIVE_MIN_WARNING,
                        "Reservation expiring soon",
                        "Your reservation for spot " + spotLabel +
                                " expires in 5 minutes. Please head to your car."
                );
            }

            log.info("5-minute warning sent for reservation {} (spot {}, {} members notified)",
                    reservation.getId(), spotLabel, members.size());
        }
    }
}