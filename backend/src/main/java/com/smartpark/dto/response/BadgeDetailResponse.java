// Response DTO for badge detail in profile.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Full detail for a badge returned under the /profile/badges endpoint,
 * including all members and registered cars.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BadgeDetailResponse {

    private Long badgeId;
    private String badgeType;
    private String status;
    private int pointsBalance;
    private List<MemberInfo> members;
    private List<CarInfo> cars;

    /**
     * A single member belonging to this badge.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MemberInfo {
        private Long userId;
        private String name;
        private String status;
    }

    /**
     * A car registered to this badge.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CarInfo {
        private String plate;
        private String owner;
    }
}