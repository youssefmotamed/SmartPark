// REST controller for guard-specific operations: guest parking, spot overrides, and active reservation listing.
package com.smartpark.controller;

import com.smartpark.dto.request.CreateGuestParkingRequest;
import com.smartpark.dto.request.SpotOverrideRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.GuestParkingResponse;
import com.smartpark.dto.response.GuardReservationResponse;
import com.smartpark.service.GuardService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * All endpoints require the GUARD role (enforced by SecurityConfig + @PreAuthorize).
 */
@RestController
@RequestMapping("/api/v1/guard")
@RequiredArgsConstructor
public class GuardController {

    private final GuardService guardService;

    /**
     * Creates a guest parking session for a non-registered vehicle in Zone C.
     *
     * @param request spot ID, guest plate, and optional purpose
     * @return 201 with the new guest parking record
     */
    @PostMapping("/guest-parking")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<GuestParkingResponse>> createGuestParking(
            @Valid @RequestBody CreateGuestParkingRequest request) {
        GuestParkingResponse response = guardService.createGuestParking(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Guest parking created"));
    }

    /**
     * Marks a guest parking session as completed and frees the spot.
     *
     * @param id the guest parking session ID
     * @return 200 with the completed record
     */
    @PatchMapping("/guest-parking/{id}/complete")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<GuestParkingResponse>> completeGuestParking(
            @PathVariable Long id) {
        GuestParkingResponse response = guardService.completeGuestParking(id);
        return ResponseEntity.ok(ApiResponse.success(response, "Guest parking completed"));
    }

    /**
     * Manually overrides a spot's status (e.g. correcting a camera error).
     *
     * @param spotId  the spot to override
     * @param request new status and reason
     * @return 200 on success
     */
    @PatchMapping("/spots/{spotId}/override")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<Void>> overrideSpotStatus(
            @PathVariable Long spotId,
            @Valid @RequestBody SpotOverrideRequest request) {
        guardService.overrideSpotStatus(spotId, request);
        return ResponseEntity.ok(ApiResponse.success(null, "Spot status updated successfully"));
    }

    /**
     * Returns all active student reservations and active guest parking sessions.
     * Reservations (ACTIVE + ENTERED) appear first, then guest sessions.
     *
     * @return 200 with a combined list
     */
    @GetMapping("/reservations")
    @PreAuthorize("hasRole('GUARD')")
    public ResponseEntity<ApiResponse<List<GuardReservationResponse>>> getActiveReservations() {
        List<GuardReservationResponse> list = guardService.getActiveReservations();
        return ResponseEntity.ok(ApiResponse.success(list));
    }
}