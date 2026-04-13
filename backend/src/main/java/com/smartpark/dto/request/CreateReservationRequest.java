// Request DTO for creating a new parking reservation.
package com.smartpark.dto.request;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/**
 * Carries the data required to create a regular (geolocation-gated) reservation.
 * Latitude and longitude are mandatory here; advance reservations use a separate endpoint.
 */
public class CreateReservationRequest {

    @NotNull(message = "Spot ID is required")
    private Long spotId;

    @NotNull(message = "Badge ID is required")
    private Long badgeId;

    @NotNull(message = "Expected leave time is required")
    @Future(message = "Expected leave time must be in the future")
    private LocalDateTime expectedLeaveTime;

    // Nullable — geolocation is not always available (GPS off, indoor, emulator).
    // The service treats a null position the same as being too far.
    private Double latitude;

    private Double longitude;

    public Long getSpotId() { return spotId; }
    public void setSpotId(Long spotId) { this.spotId = spotId; }

    public Long getBadgeId() { return badgeId; }
    public void setBadgeId(Long badgeId) { this.badgeId = badgeId; }

    public LocalDateTime getExpectedLeaveTime() { return expectedLeaveTime; }
    public void setExpectedLeaveTime(LocalDateTime expectedLeaveTime) { this.expectedLeaveTime = expectedLeaveTime; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
}
