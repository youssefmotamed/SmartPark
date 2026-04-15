// Service handling reward listing and redemption logic for the student role.
package com.smartpark.service;

import com.smartpark.dto.response.RedemptionHistoryResponse;
import com.smartpark.dto.response.RedemptionResponse;
import com.smartpark.dto.response.RewardResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.PointsLedger;
import com.smartpark.model.Reward;
import com.smartpark.model.RewardRedemption;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.PointsTransactionType;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.PointsLedgerRepository;
import com.smartpark.repository.RewardRedemptionRepository;
import com.smartpark.repository.RewardRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Handles all reward-related operations: listing available rewards with affordability flags,
 * transactionally redeeming a reward by deducting points, and retrieving redemption history.
 */
@Service
@RequiredArgsConstructor
public class RewardService {

    private static final Logger log = LoggerFactory.getLogger(RewardService.class);

    private final RewardRepository rewardRepository;
    private final RewardRedemptionRepository rewardRedemptionRepository;
    private final PointsLedgerRepository pointsLedgerRepository;
    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final UserRepository userRepository;

    /**
     * Returns all rewards, annotated with whether the student can currently afford each one.
     * If the student has no active badge, an empty list is returned rather than throwing.
     *
     * @param userId the authenticated student's ID
     * @return list of reward response DTOs with {@code canAfford} flag set
     */
    public List<RewardResponse> getRewards(Long userId) {
        Optional<Badge> badgeOpt = findActiveBadgeOptional(userId);
        if (badgeOpt.isEmpty()) {
            return List.of();
        }

        int currentBalance = badgeOpt.get().getPointsBalance();
        return rewardRepository.findAll().stream()
                .map(r -> RewardResponse.fromEntity(r, currentBalance))
                .collect(Collectors.toList());
    }

    /**
     * Redeems a reward for the student by deducting points from their active badge balance,
     * persisting a ledger entry, and recording the redemption.
     *
     * @param rewardId the ID of the reward to redeem
     * @param userId   the authenticated student's ID
     * @return confirmation DTO with redemption details and remaining balance
     * @throws ResourceNotFoundException if the reward does not exist
     * @throws BusinessRuleException     if the reward is inactive, the student has no active badge,
     *                                   or the badge balance is insufficient
     */
    @Transactional
    public RedemptionResponse redeemReward(Long rewardId, Long userId) {
        // 1. Find reward
        Reward reward = rewardRepository.findById(rewardId)
                .orElseThrow(() -> new ResourceNotFoundException("Reward not found: " + rewardId));

        // 2. Ensure reward is currently available
        if (!Boolean.TRUE.equals(reward.getIsActive())) {
            throw new BusinessRuleException("REWARD_INACTIVE", "This reward is not currently available");
        }

        // 3. Find active badge
        Badge badge = findActiveBadgeOptional(userId)
                .orElseThrow(() -> new BusinessRuleException("NO_ACTIVE_BADGE", "You do not have an active badge"));

        // 4. Check sufficient balance
        if (badge.getPointsBalance() < reward.getPointsCost()) {
            throw new BusinessRuleException("INSUFFICIENT_POINTS",
                    "You do not have enough points. Required: " + reward.getPointsCost()
                            + ", Available: " + badge.getPointsBalance());
        }

        // 5a. Create SPENT ledger entry (points stored as negative)
        PointsLedger ledger = PointsLedger.builder()
                .badge(badge)
                .transactionType(PointsTransactionType.SPENT)
                .points(-reward.getPointsCost())
                .description("Redeemed: " + reward.getRewardName())
                .earnedAt(LocalDateTime.now())
                .expiresAt(null)
                .build();
        ledger = pointsLedgerRepository.save(ledger);

        // 5c. Deduct from badge balance and persist
        badge.setPointsBalance(badge.getPointsBalance() - reward.getPointsCost());
        badgeRepository.save(badge);

        // 6. Record the redemption
        RewardRedemption redemption = RewardRedemption.builder()
                .user(userRepository.getReferenceById(userId))
                .reward(reward)
                .pointsLedger(ledger)
                .redeemedAt(LocalDateTime.now())
                .build();
        redemption = rewardRedemptionRepository.save(redemption);

        log.info("Reward {} redeemed by user {} for {} points", rewardId, userId, reward.getPointsCost());

        return RedemptionResponse.builder()
                .redemptionId(redemption.getId())
                .rewardName(reward.getRewardName())
                .pointsDeducted(reward.getPointsCost())
                .remainingBalance(badge.getPointsBalance())
                .redeemedAt(redemption.getRedeemedAt())
                .build();
    }

    /**
     * Returns the full redemption history for a student, ordered by most recent first.
     *
     * @param userId the authenticated student's ID
     * @return list of redemption history DTOs
     */
    public List<RedemptionHistoryResponse> getRedemptionHistory(Long userId) {
        return rewardRedemptionRepository.findByUserIdOrderByRedeemedAtDesc(userId).stream()
                .map(RedemptionHistoryResponse::fromEntity)
                .collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Finds the first active badge that the user is an accepted member of, if any.
     *
     * @param userId the student's ID
     * @return an {@link Optional} containing the active badge, or empty if none exists
     */
    private Optional<Badge> findActiveBadgeOptional(Long userId) {
        List<BadgeMember> memberships = badgeMemberRepository.findByUserId(userId);
        return memberships.stream()
                .filter(m -> m.getStatus() == BadgeMemberStatus.ACCEPTED)
                .filter(m -> m.getBadge().getStatus() == BadgeStatus.ACTIVE)
                .map(BadgeMember::getBadge)
                .findFirst();
    }
}