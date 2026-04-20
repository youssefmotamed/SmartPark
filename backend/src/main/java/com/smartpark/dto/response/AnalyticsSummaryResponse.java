// DTO containing real-time parking analytics for the admin dashboard.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Summary of parking lot status, activity counts, badge states, and user counts.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyticsSummaryResponse {

    private long totalSpots;
    private long occupiedSpots;
    private long reservedSpots;
    private long availableSpots;
    private long unavailableSpots;
    private Double occupancyRate;

    private long reservationsToday;
    private long violationsToday;

    private long activeBadges;
    private long suspendedBadges;

    private long totalStudents;
    private long totalGuards;
}