// Response DTO for the active reservation on a badge.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Returned by GET /api/v1/badges/{id}/reservation.
 * Describes the currently active or entered reservation for the badge.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BadgeReservationResponse {

    private Long reservationId;
    private String spotLabel;
    private String zoneCode;
    private String status;
    private String reservedByName;
    private LocalDateTime reservedAt;
    private LocalDateTime expectedLeaveTime;
    private LocalDateTime expiresAt;
}