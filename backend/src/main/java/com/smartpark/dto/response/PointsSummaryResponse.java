// DTO returned by GET /api/v1/points/summary — aggregated points statistics for the user's active badge.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Aggregated points summary for the user's active badge.
 * Returned by GET /api/v1/points/summary.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PointsSummaryResponse {

    /** Total points earned across all sessions for this badge. */
    private int totalEarned;

    /** Total points spent on rewards for this badge. */
    private int totalSpent;

    /** Points that will expire within the next 30 days. */
    private int expiringSoon;

    /** Current live balance on the badge. */
    private int currentBalance;
}