// Response DTO for zone data returned by the zones endpoint.
package com.smartpark.dto.response;

public class ZoneResponse {

    private Long id;
    private String zoneCode;
    private String zoneName;
    private String accessType;

    private ZoneResponse() {}

    public ZoneResponse(Long id, String zoneCode, String zoneName, String accessType) {
        this.id = id;
        this.zoneCode = zoneCode;
        this.zoneName = zoneName;
        this.accessType = accessType;
    }

    public Long getId() { return id; }
    public String getZoneCode() { return zoneCode; }
    public String getZoneName() { return zoneName; }
    public String getAccessType() { return accessType; }
}