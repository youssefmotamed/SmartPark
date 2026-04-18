// Service responsible for points calculation on exit scan and querying the points ledger.
package com.smartpark.service;

import com.smartpark.dto.response.PointsBalanceResponse;
import com.smartpark.dto.response.PointsLedgerResponse;
import com.smartpark.dto.response.PointsSummaryResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.PointsLedger;
import com.smartpark.model.Reservation;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.PointsTransactionType;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.PointsLedgerRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Handles all points-related logic: calculating and awarding points at exit,
 * and exposing balance, history, and summary queries to the student API.
 */
@Service
@RequiredArgsConstructor
public class PointsService {

    private static final Logger log = LoggerFactory.getLogger(PointsService.class);

    private final PointsLedgerRepository pointsLedgerRepository;
    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final NotificationService notificationService;

    /**
     * Calculates points for a completed reservation, persists a ledger entry,
     * updates the badge balance, stamps the reservation, and notifies all badge members.
     *
     * <p>The caller (GateService) is responsible for saving the reservation after this method returns.
     * This method only sets {@code reservation.pointsEarned} — it does not call the repository itself.
     *
     * @param reservation the completed reservation (status must already be COMPLETED)
     * @return the final points awarded (0 if none)
     */
    @Transactional
    public int calculateAndAwardPoints(Reservation reservation) {
        LocalDateTime exitTime = LocalDateTime.now();
        LocalDateTime expectedLeaveTime = reservation.getExpectedLeaveTime();

        if (expectedLeaveTime == null) {
            return 0;
        }

        // minutesDiff = expectedLeaveTime - exitTime
        // Positive → early departure, Negative → late departure, 0 → on time
        long minutesDiff = ChronoUnit.MINUTES.between(exitTime, expectedLeaveTime);

        int basePoints;
        if (minutesDiff >= 0) {
            // Early or exactly on time
            if (minutesDiff <= 5) {
                basePoints = 10;
            } else if (minutesDiff <= 15) {
                basePoints = 8;
            } else if (minutesDiff <= 30) {
                basePoints = 5;
            } else {
                basePoints = 0;
            }
        } else {
            // Late
            long minutesLate = -minutesDiff;
            if (minutesLate <= 10) {
                basePoints = 8;
            } else if (minutesLate <= 20) {
                basePoints = 5;
            } else if (minutesLate <= 30) {
                basePoints = 3;
            } else if (minutesLate <= 60) {
                basePoints = 1;
            } else {
                basePoints = 0;
            }
        }

        Badge badge = reservation.getBadge();
        double multiplier = multiplierFor(badge);
        int finalPoints = (int) Math.round(basePoints * multiplier);

        if (finalPoints > 0) {
            LocalDateTime now = LocalDateTime.now();

            // Persist ledger entry
            PointsLedger ledger = PointsLedger.builder()
                    .badge(badge)
                    .reservation(reservation)
                    .transactionType(PointsTransactionType.EARNED)
                    .points(finalPoints)
                    .description("Exit scan: " + basePoints + " pts x " + multiplier + " multiplier")
                    .earnedAt(now)
                    .expiresAt(now.plusDays(365))
                    .build();
            pointsLedgerRepository.save(ledger);

            // Update badge balance
            badge.setPointsBalance(badge.getPointsBalance() + finalPoints);
            badgeRepository.save(badge);

            // Stamp the reservation (caller saves it via dirty check)
            reservation.setPointsEarned(finalPoints);

            // Notify all accepted badge members
            String spotLabel = reservation.getSpot().getSpotLabel();
            String notifTitle = "Points earned";
            String notifMessage = "You earned " + finalPoints + " points for your parking session at spot " + spotLabel;

            List<BadgeMember> members = badgeMemberRepository.findByBadgeIdAndStatus(
                    badge.getId(), BadgeMemberStatus.ACCEPTED);
            for (BadgeMember member : members) {
                notificationService.createNotification(
                        member.getUser().getId(), NotificationType.POINTS_EARNED, notifTitle, notifMessage);
            }

            log.info("Points awarded: {} pts for reservation {} (base={}, multiplier={})",
                    finalPoints, reservation.getId(), basePoints, multiplier);
        }

        return finalPoints;
    }

    /**
     * Returns the current points balance and multiplier for the user's active badge.
     *
     * @param userId the authenticated student's ID
     * @return balance response containing badge ID, type, balance, and multiplier
     * @throws ResourceNotFoundException if the user has no active badge membership
     */
    @Transactional(readOnly = true)
    public PointsBalanceResponse getBalance(Long userId) {
        Badge badge = findActiveBadgeForUser(userId);
        return PointsBalanceResponse.builder()
                .badgeId(badge.getId())
                .badgeType(badge.getBadgeType().name())
                .pointsBalance(badge.getPointsBalance())
                .multiplier(multiplierFor(badge))
                .build();
    }

    /**
     * Returns a paginated transaction history for the user's active badge.
     *
     * @param userId     the authenticated student's ID
     * @param typeFilter optional transaction type filter (e.g. "EARNED"); {@code null} returns all types
     * @param pageable   pagination and sorting config
     * @return page of ledger entry DTOs ordered by earnedAt DESC
     * @throws ResourceNotFoundException if the user has no active badge
     * @throws BusinessRuleException     if {@code typeFilter} is not a valid {@link PointsTransactionType}
     */
    @Transactional(readOnly = true)
    public Page<PointsLedgerResponse> getHistory(Long userId, String typeFilter, Pageable pageable) {
        Badge badge = findActiveBadgeForUser(userId);

        Page<PointsLedger> page;
        if (typeFilter != null && !typeFilter.isBlank()) {
            PointsTransactionType type;
            try {
                type = PointsTransactionType.valueOf(typeFilter.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new BusinessRuleException("INVALID_TYPE", "Invalid transaction type: " + typeFilter);
            }
            page = pointsLedgerRepository.findByBadgeIdAndTransactionTypeOrderByEarnedAtDesc(
                    badge.getId(), type, pageable);
        } else {
            page = pointsLedgerRepository.findByBadgeIdOrderByEarnedAtDesc(badge.getId(), pageable);
        }

        return page.map(PointsLedgerResponse::fromEntity);
    }

    /**
     * Returns aggregated points statistics (total earned, spent, expiring soon, and current balance)
     * for the user's active badge.
     *
     * @param userId the authenticated student's ID
     * @return summary response with aggregated totals
     * @throws ResourceNotFoundException if the user has no active badge
     */
    @Transactional(readOnly = true)
    public PointsSummaryResponse getSummary(Long userId) {
        Badge badge = findActiveBadgeForUser(userId);
        List<PointsLedger> allEntries = pointsLedgerRepository.findByBadgeId(badge.getId());

        LocalDateTime expiryCutoff = LocalDateTime.now().plusDays(30);

        int totalEarned = allEntries.stream()
                .filter(e -> e.getTransactionType() == PointsTransactionType.EARNED)
                .mapToInt(PointsLedger::getPoints)
                .sum();

        int totalSpent = allEntries.stream()
                .filter(e -> e.getTransactionType() == PointsTransactionType.SPENT)
                .mapToInt(e -> Math.abs(e.getPoints()))
                .sum();

        int expiringSoon = allEntries.stream()
                .filter(e -> e.getTransactionType() == PointsTransactionType.EARNED
                        && e.getExpiresAt() != null
                        && e.getExpiresAt().isBefore(expiryCutoff))
                .mapToInt(PointsLedger::getPoints)
                .sum();

        return PointsSummaryResponse.builder()
                .totalEarned(totalEarned)
                .totalSpent(totalSpent)
                .expiringSoon(expiringSoon)
                .currentBalance(badge.getPointsBalance())
                .build();
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Finds the first active badge that the user is an accepted member of.
     *
     * @param userId the student's ID
     * @return the active {@link Badge}
     * @throws ResourceNotFoundException if no active badge membership exists
     */
    private Badge findActiveBadgeForUser(Long userId) {
        List<BadgeMember> memberships = badgeMemberRepository.findByUserId(userId);
        return memberships.stream()
                .filter(m -> m.getStatus() == BadgeMemberStatus.ACCEPTED)
                .filter(m -> m.getBadge().getStatus() == BadgeStatus.ACTIVE)
                .map(BadgeMember::getBadge)
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("No active badge found"));
    }

    /**
     * Returns the points multiplier for the given badge type.
     *
     * @param badge the badge whose type determines the multiplier
     * @return multiplier value between 1.0 and 1.8
     */
    private double multiplierFor(Badge badge) {
        return switch (badge.getBadgeType()) {
            case INDIVIDUAL -> 1.0;
            case CARPOOL_2 -> 1.2;
            case CARPOOL_3 -> 1.4;
            case CARPOOL_4 -> 1.6;
            case CARPOOL_5 -> 1.8;
        };
    }
}