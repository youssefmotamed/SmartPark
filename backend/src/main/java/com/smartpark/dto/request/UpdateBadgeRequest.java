// Request DTO for admin patching badge fields.
package com.smartpark.dto.request;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UpdateBadgeRequest {

    private String badgeType;
    private Integer violationCount;
    private LocalDateTime expiresAt;
}