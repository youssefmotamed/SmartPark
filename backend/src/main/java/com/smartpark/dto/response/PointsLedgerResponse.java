// DTO returned in the points history list — maps a single PointsLedger entry.
package com.smartpark.dto.response;

import com.smartpark.model.PointsLedger;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response payload for a single points ledger entry.
 * Used in the paginated history response at GET /api/v1/points/history.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PointsLedgerResponse {

    /** Database ID of the ledger entry. */
    private Long id;

    /** Points amount (positive for earned/pooled, negative for spent). */
    private int points;

    /** Transaction type string (EARNED, SPENT, DIVIDED, POOLED, EXPIRED). */
    private String transactionType;

    /** Human-readable description of the transaction (e.g. "Exit scan: 10 pts x 1.2 multiplier"). */
    private String description;

    /** Timestamp when the points were earned or recorded. */
    private LocalDateTime earnedAt;

    /** Timestamp when these points expire, or {@code null} for non-expiring entries. */
    private LocalDateTime expiresAt;

    /**
     * Maps a {@link PointsLedger} entity to this response DTO.
     *
     * @param p the ledger entity to map
     * @return a populated {@code PointsLedgerResponse}
     */
    public static PointsLedgerResponse fromEntity(PointsLedger p) {
        return PointsLedgerResponse.builder()
                .id(p.getId())
                .points(p.getPoints())
                .transactionType(p.getTransactionType().name())
                .description(p.getDescription())
                .earnedAt(p.getEarnedAt())
                .expiresAt(p.getExpiresAt())
                .build();
    }
}