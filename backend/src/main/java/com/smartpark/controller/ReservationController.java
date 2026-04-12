// REST controller for student reservation endpoints.
package com.smartpark.controller;

import com.smartpark.dto.request.CreateReservationRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.ReservationResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes reservation endpoints under {@code /api/v1/reservations}.
 * All endpoints require an authenticated STUDENT role.
 */
@RestController
@RequestMapping("/api/v1/reservations")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    /**
     * Creates a new parking reservation for the authenticated student.
     *
     * <p>Runs a full validation chain: badge ownership, suspension, spot availability,
     * zone access, geolocation, and same-spot restriction before persisting.</p>
     *
     * @param request validated request body with spotId, badgeId, expectedLeaveTime, and coordinates
     * @return 201 Created with the new {@link ReservationResponse}
     */
    @PostMapping
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<ReservationResponse>> createReservation(
            @Valid @RequestBody CreateReservationRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();
        ReservationResponse response = reservationService.createReservation(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    /**
     * Cancels an active reservation belonging to the authenticated student.
     *
     * <p>Verifies badge membership ownership and that the reservation is still in ACTIVE status
     * before cancelling. Frees the associated spot back to AVAILABLE.</p>
     *
     * @param id the ID of the reservation to cancel
     * @return 200 OK with no data on success
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<Void>> cancelReservation(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        reservationService.cancelReservation(id, userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}