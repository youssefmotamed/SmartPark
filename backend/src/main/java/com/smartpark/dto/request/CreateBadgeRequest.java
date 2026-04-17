// Request DTO for creating a new parking badge (individual or carpool).
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Request body for POST /api/v1/badges.
 * The student specifies the badge type and the semester it applies to.
 */
@Data
public class CreateBadgeRequest {

    @NotBlank(message = "Badge type is required")
    private String badgeType;

    @NotNull(message = "Semester number is required")
    private Integer semesterNumber;

    @NotNull(message = "Semester year is required")
    private Integer semesterYear;
}
