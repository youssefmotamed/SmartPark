// REST controller for receiving camera spot-occupancy updates from the camera processor.
package com.smartpark.controller;

import com.smartpark.dto.request.CameraSpotStatusRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.CameraUpdateResponse;
import com.smartpark.service.CameraService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Handles POST /api/v1/camera/spot-status.
 *
 * <p>This endpoint is NOT protected by JWT. Authentication is via a shared
 * API key in the {@code X-API-Key} request header, validated against the
 * {@code camera.api-key} application property.
 */
@RestController
@RequestMapping("/api/v1/camera")
@RequiredArgsConstructor
public class CameraController {

    private static final Logger log = LoggerFactory.getLogger(CameraController.class);

    private final CameraService cameraService;

    @Value("${camera.api-key}")
    private String cameraApiKey;

    /**
     * Receives a batch of spot-occupancy readings from the camera processor.
     *
     * @param apiKey  the shared API key from the {@code X-API-Key} header
     * @param request the payload containing per-spot occupancy updates
     * @return a summary of what was changed
     */
    @PostMapping("/spot-status")
    public ResponseEntity<ApiResponse<CameraUpdateResponse>> updateSpotStatus(
            @RequestHeader("X-API-Key") String apiKey,
            @RequestBody CameraSpotStatusRequest request) {

        if (!cameraApiKey.equals(apiKey)) {
            log.warn("Camera endpoint called with invalid API key");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("INVALID_API_KEY", "Invalid API key"));
        }

        CameraUpdateResponse response = cameraService.processSpotStatuses(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}