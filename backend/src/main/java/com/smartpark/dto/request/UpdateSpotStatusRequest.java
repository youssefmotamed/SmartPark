// Request DTO for admin updating a spot's status.
package com.smartpark.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateSpotStatusRequest {

    @NotBlank
    private String newStatus;
}