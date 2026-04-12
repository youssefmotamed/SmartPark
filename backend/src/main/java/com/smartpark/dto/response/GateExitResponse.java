// DTO returned by the gate exit scan endpoint.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response payload for a gate exit QR code scan.
 * Fields are {@code null} when the scan is rejected (QR not found or wrong status).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GateExitResponse {

    /** The ID of the reservation that was scanned, or {@code null} if the QR code was not found. */
    private Long reservationId;

    /** The label of the parking spot being vacated, or {@code null} if the scan failed. */
    private String spotLabel;

    /** Full name of the badge creator (student), or {@code null} if the scan failed. */
    private String studentName;

    /** Points awarded for this session. Always 0 until Phase 4 points calculation is implemented. */
    private int pointsEarned;

    /** Whether the exit was successfully recorded (false when QR not found or reservation has wrong status). */
    private boolean exitRecorded;
}