// Request DTO for a guard reporting a parking violation by plate number.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReportViolationRequest {

    @NotBlank(message = "Plate number is required")
    private String plateNumber;

    @NotBlank(message = "Violation type is required")
    private String violationType;

    private String notes;
}