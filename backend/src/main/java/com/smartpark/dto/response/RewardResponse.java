// DTO returned for each reward entry, including whether the student can currently afford it.
package com.smartpark.dto.response;

import com.smartpark.model.Reward;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO representing a single redeemable reward.
 * The {@code canAfford} flag is computed against the student's current badge balance
 * at query time and must not be cached.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RewardResponse {

    private Long id;
    private String rewardName;
    private String description;
    private int pointsCost;
    private String rewardType;
    private boolean isActive;
    private boolean canAfford;

    /**
     * Builds a {@link RewardResponse} from a {@link Reward} entity and the student's current balance.
     *
     * @param reward         the reward entity
     * @param currentBalance the student's active badge points balance
     * @return populated response DTO
     */
    public static RewardResponse fromEntity(Reward reward, int currentBalance) {
        return RewardResponse.builder()
                .id(reward.getId())
                .rewardName(reward.getRewardName())
                .description(reward.getDescription())
                .pointsCost(reward.getPointsCost())
                .rewardType(reward.getRewardType())
                .isActive(Boolean.TRUE.equals(reward.getIsActive()))
                .canAfford(currentBalance >= reward.getPointsCost())
                .build();
    }
}
