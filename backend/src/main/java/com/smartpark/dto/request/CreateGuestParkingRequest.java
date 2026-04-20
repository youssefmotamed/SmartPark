// DTO for creating a guest parking session in a GUARD_ONLY zone.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateGuestParkingRequest {

    @NotNull(message = "Spot ID is required")
    private Long spotId;

    @NotBlank(message = "Guest plate number is required")
    private String guestPlateNumber;

    private String purpose;
}