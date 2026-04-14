// Incoming payload from the camera processor reporting the occupancy state of each parking spot.
package com.smartpark.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

/**
 * Request body sent by the camera processor to POST /api/v1/camera/spot-status.
 * Contains a timestamp and a list of per-spot occupancy updates.
 */
@Data
public class CameraSpotStatusRequest {

    /** ISO-8601 UTC timestamp of the camera capture (e.g. "2026-04-14T10:00:00Z"). */
    private String timestamp;

    /** One entry per monitored parking spot. */
    private List<SpotStatusUpdate> spots;

    /**
     * A single spot's occupancy reading from the camera processor.
     */
    @Data
    public static class SpotStatusUpdate {

        /** The spot label as stored in the database (e.g. "A1", "B3"). */
        @JsonProperty("spot_label")
        private String spotLabel;

        /** True when the camera detects a vehicle in this spot; false when the spot appears empty. */
        @JsonProperty("is_occupied")
        private boolean isOccupied;
    }
}