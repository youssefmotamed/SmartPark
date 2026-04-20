// Request DTO for admin suspending a badge.
package com.smartpark.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class SuspendBadgeRequest {

    @NotNull
    @Min(1)
    private Integer suspensionDays;

    @NotBlank
    private String reason;
}