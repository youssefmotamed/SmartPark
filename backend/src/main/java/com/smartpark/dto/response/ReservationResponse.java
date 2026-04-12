// Response DTO returned after creating or fetching a reservation.
package com.smartpark.dto.response;

import com.smartpark.model.Reservation;

import java.time.LocalDateTime;

/**
 * Carries the reservation data returned to the client.
 * Built from a {@link Reservation} entity via {@link #fromEntity(Reservation)}.
 */
public class ReservationResponse {

    private Long id;
    private String spotLabel;
    private String zoneCode;
    private String status;
    private String qrCodeData;
    private LocalDateTime reservedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime expectedLeaveTime;
    private String badgeType;

    private ReservationResponse() {}

    private ReservationResponse(Long id, String spotLabel, String zoneCode, String status,
                                String qrCodeData, LocalDateTime reservedAt, LocalDateTime expiresAt,
                                LocalDateTime expectedLeaveTime, String badgeType) {
        this.id = id;
        this.spotLabel = spotLabel;
        this.zoneCode = zoneCode;
        this.status = status;
        this.qrCodeData = qrCodeData;
        this.reservedAt = reservedAt;
        this.expiresAt = expiresAt;
        this.expectedLeaveTime = expectedLeaveTime;
        this.badgeType = badgeType;
    }

    /**
     * Converts a {@link Reservation} entity into a {@link ReservationResponse} DTO.
     */
    public static ReservationResponse fromEntity(Reservation reservation) {
        return new ReservationResponse(
                reservation.getId(),
                reservation.getSpot().getSpotLabel(),
                reservation.getSpot().getZone().getZoneCode(),
                reservation.getStatus().name(),
                reservation.getQrCodeData(),
                reservation.getReservedAt(),
                reservation.getExpiresAt(),
                reservation.getExpectedLeaveTime(),
                reservation.getBadge().getBadgeType().name()
        );
    }

    public Long getId() { return id; }
    public String getSpotLabel() { return spotLabel; }
    public String getZoneCode() { return zoneCode; }
    public String getStatus() { return status; }
    public String getQrCodeData() { return qrCodeData; }
    public LocalDateTime getReservedAt() { return reservedAt; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public LocalDateTime getExpectedLeaveTime() { return expectedLeaveTime; }
    public String getBadgeType() { return badgeType; }
}