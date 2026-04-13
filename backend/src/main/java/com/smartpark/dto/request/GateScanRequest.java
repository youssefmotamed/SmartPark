// DTO for gate QR scan requests — carries the QR code data scanned by the guard.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Request body for gate entry/exit scan endpoints.
 */
@Data
public class GateScanRequest {

    @NotBlank(message = "QR code data is required")
    private String qrCodeData;
}
