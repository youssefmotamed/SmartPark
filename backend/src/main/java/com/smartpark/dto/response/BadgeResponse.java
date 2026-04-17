// Response DTO returned after badge creation and for badge detail views.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Full badge detail returned by POST /api/v1/badges and GET /api/v1/badges/{id}.
 * Includes member list (with invite eligibility) and registered cars.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BadgeResponse {

    private Long badgeId;
    private String badgeType;
    private String status;
    private Integer pointsBalance;
    private Integer maxSlots;
    private Integer violationCount;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;

    private List<MemberInfo> members;
    private List<CarInfo> cars;

    /** A single member belonging to this badge. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MemberInfo {
        private Long userId;
        private String name;
        private String status;
        private Boolean canInvite;
    }

    /** A car registered to this badge. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CarInfo {
        private String plate;
        private String ownerName;
    }
}