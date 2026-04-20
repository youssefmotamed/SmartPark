// DTO for a guard manually overriding a spot's status.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SpotOverrideRequest {

    /** Values: AVAILABLE, OCCUPIED, UNAVAILABLE */
    @NotBlank(message = "New status is required")
    private String newStatus;

    /** Values: CAMERA_ERROR, LEFT_UNDETECTED, MAINTENANCE, EVENT, OTHER */
    @NotBlank(message = "Reason is required")
    private String reason;
}