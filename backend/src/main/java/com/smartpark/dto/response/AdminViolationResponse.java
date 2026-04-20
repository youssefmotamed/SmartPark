// DTO for admin violation listing, including badge and guard details.
package com.smartpark.dto.response;

import com.smartpark.model.Violation;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for a violation record as seen by an admin.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminViolationResponse {

    private Long violationId;
    private String plateNumber;
    private String violationType;
    private Integer suspensionDays;
    private String guardName;
    private Long badgeId;
    private String badgeType;
    private LocalDateTime createdAt;

    public static AdminViolationResponse fromEntity(Violation violation) {
        return AdminViolationResponse.builder()
                .violationId(violation.getId())
                .plateNumber(violation.getPlateNumber())
                .violationType(violation.getViolationType().name())
                .suspensionDays(violation.getSuspensionDays())
                .guardName(violation.getReportedByGuard().getFullName())
                .badgeId(violation.getBadge().getId())
                .badgeType(violation.getBadge().getBadgeType().name())
                .createdAt(violation.getCreatedAt())
                .build();
    }
}