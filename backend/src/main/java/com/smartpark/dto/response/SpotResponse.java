// Response DTO for spot data returned by the spots endpoints.
package com.smartpark.dto.response;

import java.time.LocalDateTime;

public class SpotResponse {

    private Long id;
    private String spotLabel;
    private String zoneCode;
    private String zoneName;
    private String status;
    private LocalDateTime statusUpdatedAt;

    private SpotResponse() {}

    public SpotResponse(Long id, String spotLabel, String zoneCode, String zoneName,
                        String status, LocalDateTime statusUpdatedAt) {
        this.id = id;
        this.spotLabel = spotLabel;
        this.zoneCode = zoneCode;
        this.zoneName = zoneName;
        this.status = status;
        this.statusUpdatedAt = statusUpdatedAt;
    }

    public Long getId() { return id; }
    public String getSpotLabel() { return spotLabel; }
    public String getZoneCode() { return zoneCode; }
    public String getZoneName() { return zoneName; }
    public String getStatus() { return status; }
    public LocalDateTime getStatusUpdatedAt() { return statusUpdatedAt; }
}