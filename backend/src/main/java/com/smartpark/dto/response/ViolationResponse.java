// Response DTO returned after a guard successfully reports a parking violation.
package com.smartpark.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ViolationResponse {

    private Long violationId;
    private Long badgeId;
    private String badgeType;
    private Integer suspensionDays;
    private LocalDateTime suspendedUntil;
    private List<String> affectedStudents;
}