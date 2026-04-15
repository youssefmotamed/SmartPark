// DTO returned by GET /api/v1/points/balance — shows the user's current badge balance and multiplier.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response payload for the points balance endpoint.
 * Contains the active badge's current balance, type, and the carpool multiplier applied to earned points.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PointsBalanceResponse {

    /** ID of the active badge that owns these points. */
    private Long badgeId;

    /** Badge type string (e.g. INDIVIDUAL, CARPOOL_2). */
    private String badgeType;

    /** Current points balance on the badge. */
    private int pointsBalance;

    /** Multiplier applied to base points at exit scan (1.0 for INDIVIDUAL, up to 1.8 for CARPOOL_5). */
    private double multiplier;
}