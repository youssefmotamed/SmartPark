// DTO representing a single past reward redemption in the student's history list.
package com.smartpark.dto.response;

import com.smartpark.model.RewardRedemption;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for a single entry in the student's reward redemption history.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RedemptionHistoryResponse {

    private Long id;
    private String rewardName;
    private String rewardType;
    private int pointsDeducted;
    private LocalDateTime redeemedAt;

    /**
     * Builds a {@link RedemptionHistoryResponse} from a {@link RewardRedemption} entity.
     * The {@code pointsDeducted} value is stored as a negative integer in the ledger;
     * this method returns the absolute value so the client always sees a positive deduction amount.
     *
     * @param r the reward redemption entity
     * @return populated history response DTO
     */
    public static RedemptionHistoryResponse fromEntity(RewardRedemption r) {
        return RedemptionHistoryResponse.builder()
                .id(r.getId())
                .rewardName(r.getReward().getRewardName())
                .rewardType(r.getReward().getRewardType())
                .pointsDeducted(Math.abs(r.getPointsLedger().getPoints()))
                .redeemedAt(r.getRedeemedAt())
                .build();
    }
}