// Response DTO for student profile endpoint.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Carries the current user's profile data including identity, active badge summary, and total points.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileResponse {

    private Long id;
    private String fullName;
    private String studentId;
    private String email;
    private String plateNumber;
    private int totalPoints;
    private ActiveBadgeInfo activeBadge;
    private LocalDateTime createdAt;

    /**
     * Summary of the user's currently active badge, if any.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ActiveBadgeInfo {
        private Long id;
        private String type;
        private String status;
    }
}