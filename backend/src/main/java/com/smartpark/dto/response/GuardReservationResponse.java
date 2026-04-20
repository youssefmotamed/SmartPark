// DTO representing a single entry in the guard's active reservations list (either a student reservation or a guest parking session).
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GuardReservationResponse {

    /** Either "RESERVATION" or "GUEST". */
    private String type;

    // --- Shared ---
    private Long id;
    private String spotLabel;
    private String zoneCode;

    // --- RESERVATION fields ---
    private String studentName;
    private String badgeType;
    private String status;
    private LocalDateTime reservedAt;
    private LocalDateTime expectedLeaveTime;
    private List<String> plateNumbers;

    // --- GUEST fields ---
    private String guestPlateNumber;
    private String purpose;
    private Long guardId;
    private LocalDateTime createdAt;
}