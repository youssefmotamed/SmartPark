// Request DTO for creating an advance reservation using a redeemed advance-reservation token.
package com.smartpark.dto.request;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/**
 * Carries the data required to create an advance reservation.
 * Unlike {@link CreateReservationRequest}, no location coordinates are required —
 * the geolocation gate is bypassed because the student has already spent points
 * to redeem an advance-reservation token.
 */
public class AdvanceReservationRequest {

    @NotNull(message = "Spot ID is required")
    private Long spotId;

    @NotNull(message = "Badge ID is required")
    private Long badgeId;

    @NotNull(message = "Expected leave time is required")
    @Future(message = "Expected leave time must be in the future")
    private LocalDateTime expectedLeaveTime;

    public Long getSpotId() { return spotId; }
    public void setSpotId(Long spotId) { this.spotId = spotId; }

    public Long getBadgeId() { return badgeId; }
    public void setBadgeId(Long badgeId) { this.badgeId = badgeId; }

    public LocalDateTime getExpectedLeaveTime() { return expectedLeaveTime; }
    public void setExpectedLeaveTime(LocalDateTime expectedLeaveTime) { this.expectedLeaveTime = expectedLeaveTime; }
}