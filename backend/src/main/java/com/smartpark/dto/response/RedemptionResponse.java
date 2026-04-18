// DTO returned immediately after a successful reward redemption.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO confirming a successful reward redemption.
 * Includes the transaction summary and the student's remaining balance after deduction.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RedemptionResponse {

    private Long redemptionId;
    private String rewardName;
    private int pointsDeducted;
    private int remainingBalance;
    private LocalDateTime redeemedAt;
}
