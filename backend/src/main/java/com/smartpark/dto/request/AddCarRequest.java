// Request DTO for adding a car to an existing badge slot.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Body for POST /api/v1/badges/{id}/add-car.
 * Registers a new plate under the badge on behalf of an accepted member.
 */
@Data
public class AddCarRequest {

    @NotBlank(message = "Plate number is required")
    private String plateNumber;

    private String carModel;

    @NotNull(message = "forUserId is required")
    private Long forUserId;
}