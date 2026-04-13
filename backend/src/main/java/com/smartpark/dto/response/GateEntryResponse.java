// DTO returned after a guard scans a QR code at the entry gate.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Response body for the gate entry scan endpoint.
 * {@code valid=true} means the scan succeeded; {@code valid=false} means it was rejected
 * and {@code reason} explains why.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GateEntryResponse {

    /** Whether the QR code was accepted and the reservation transitioned to ENTERED. */
    private boolean valid;

    /** Parking spot label (e.g. "A3"). Populated only when {@code valid=true}. */
    private String spotLabel;

    /** Full name of the badge creator (the student who made the reservation). Populated only when {@code valid=true}. */
    private String studentName;

    /** Badge type string (e.g. "INDIVIDUAL", "CARPOOL_3"). Populated only when {@code valid=true}. */
    private String badgeType;

    /** All plate numbers registered to this badge. Populated only when {@code valid=true}. */
    private List<String> registeredPlates;

    /** ID of the reservation that was scanned. Populated only when {@code valid=true}. */
    private Long reservationId;

    /**
     * Seconds remaining on the 15-minute pre-entry timer at the moment of scan.
     * Populated only when {@code valid=true}.
     */
    private Long timeRemainingSeconds;

    /** Human-readable rejection reason. Null when {@code valid=true}. */
    private String reason;
}
