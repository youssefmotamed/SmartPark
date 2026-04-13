// REST controller for gate entry and exit scan endpoints used by guards.
package com.smartpark.controller;

import com.smartpark.dto.request.GateScanRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.GateEntryResponse;
import com.smartpark.dto.response.GateExitResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.GateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Handles QR code scanning at the parking lot entry and exit gates.
 * All endpoints require the GUARD role.
 */
@RestController
@RequestMapping("/api/v1/gate")
@RequiredArgsConstructor
public class GateController {

    private final GateService gateService;

    /**
     * Scans a QR code at the entry gate.
     * Always returns HTTP 200; inspect the {@code valid} field to determine outcome.
     *
     * @param request the QR code data from the guard's scanner
     * @return scan result including spot label, student name, and registered plates on success,
     *         or a rejection reason on failure
     */
    @PostMapping("/scan-entry")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<GateEntryResponse>> scanEntry(
            @Valid @RequestBody GateScanRequest request) {
        Long guardId = SecurityUtils.getCurrentUserId();
        GateEntryResponse response = gateService.scanEntry(guardId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * Scans a QR code at the exit gate.
     * Always returns HTTP 200; a null {@code reservationId} indicates the QR was not found,
     * while a non-null {@code reservationId} with no status change indicates the reservation
     * was not in the ENTERED state.
     *
     * @param request the QR code data from the guard's scanner
     * @return scan result including spot label, student name, and points earned (always 0 until Phase 4)
     */
    @PostMapping("/scan-exit")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<GateExitResponse>> scanExit(
            @Valid @RequestBody GateScanRequest request) {
        Long guardId = SecurityUtils.getCurrentUserId();
        GateExitResponse response = gateService.scanExit(guardId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}