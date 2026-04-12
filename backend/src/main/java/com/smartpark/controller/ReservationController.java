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
}