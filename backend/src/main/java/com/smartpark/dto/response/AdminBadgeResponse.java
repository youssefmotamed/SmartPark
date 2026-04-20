// Response DTO for admin badge management endpoints.
package com.smartpark.dto.response;

import com.smartpark.model.Badge;
import com.smartpark.model.BadgeMember;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Full badge detail returned by admin badge management endpoints, including all members.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminBadgeResponse {

    private Long badgeId;
    private String badgeType;
    private String status;
    private Integer pointsBalance;
    private Integer maxSlots;
    private Integer violationCount;
    private LocalDateTime suspendedUntil;
    private String suspensionReason;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    private List<MemberInfo> members;

    /**
     * A member belonging to this badge.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MemberInfo {
        private Long userId;
        private String name;
        private String studentId;
        private String status;
    }

    public static AdminBadgeResponse fromEntity(Badge badge, List<BadgeMember> members) {
        List<MemberInfo> memberInfos = members.stream()
                .map(m -> MemberInfo.builder()
                        .userId(m.getUser().getId())
                        .name(m.getUser().getFullName())
                        .studentId(m.getUser().getStudentId())
                        .status(m.getStatus().name())
                        .build())
                .collect(Collectors.toList());

        return AdminBadgeResponse.builder()
                .badgeId(badge.getId())
                .badgeType(badge.getBadgeType().name())
                .status(badge.getStatus().name())
                .pointsBalance(badge.getPointsBalance())
                .maxSlots(badge.getMaxSlots())
                .violationCount(badge.getViolationCount())
                .suspendedUntil(badge.getSuspendedUntil())
                .suspensionReason(badge.getSuspensionReason())
                .createdAt(badge.getCreatedAt())
                .expiresAt(badge.getExpiresAt())
                .members(memberInfos)
                .build();
    }
}