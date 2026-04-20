// DTO returned after creating or completing a guest parking session.
package com.smartpark.dto.response;

import com.smartpark.model.GuestParking;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GuestParkingResponse {

    private Long id;
    private Long spotId;
    private String spotLabel;
    private String zoneCode;
    private String guestPlateNumber;
    private String purpose;
    private String status;
    private Long guardId;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;

    public static GuestParkingResponse fromEntity(GuestParking guestParking) {
        return GuestParkingResponse.builder()
                .id(guestParking.getId())
                .spotId(guestParking.getSpot().getId())
                .spotLabel(guestParking.getSpot().getSpotLabel())
                .zoneCode(guestParking.getSpot().getZone().getZoneCode())
                .guestPlateNumber(guestParking.getGuestPlateNumber())
                .purpose(guestParking.getPurpose())
                .status(guestParking.getStatus())
                .guardId(guestParking.getCreatedByGuard().getId())
                .createdAt(guestParking.getCreatedAt())
                .completedAt(guestParking.getCompletedAt())
                .build();
    }
}