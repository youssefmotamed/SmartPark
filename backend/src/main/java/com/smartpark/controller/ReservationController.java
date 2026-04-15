// REST controller for student reservation endpoints.
package com.smartpark.controller;

import com.smartpark.dto.request.AdvanceReservationRequest;
import com.smartpark.dto.request.CreateReservationRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.ReservationResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
     * Creates an advance reservation using a redeemed advance-reservation token.
     *
     * <p>Skips the geolocation gate. All other validations (badge ownership, suspension,
     * spot availability, zone access, same-spot restriction) still apply.
     * The consumed token is marked used on success.</p>
     *
     * @param request validated request body with spotId, badgeId, and expectedLeaveTime
     * @return 201 Created with the new {@link ReservationResponse}
     */
    @PostMapping("/advance")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<ReservationResponse>> createAdvanceReservation(
            @Valid @RequestBody AdvanceReservationRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();
        ReservationResponse response = reservationService.createAdvanceReservation(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    /**
     * Returns the currently active or entered reservation for the authenticated student.
     *
     * <p>Searches across all badges the student is an accepted member of.
     * Returns 404 if the student has no active or entered reservation.</p>
     *
     * @return 200 OK with the {@link ReservationResponse}, or 404 if none exists
     */
    @GetMapping("/active")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<ReservationResponse>> getActiveReservation() {
        Long userId = SecurityUtils.getCurrentUserId();
        ReservationResponse response = reservationService.getActiveReservation(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * Returns a paginated history of past reservations for the authenticated student.
     *
     * <p>Includes reservations with status COMPLETED, EXPIRED, or CANCELLED by default.
     * An optional {@code status} query parameter narrows results to a single status.</p>
     *
     * @param status optional status filter (COMPLETED, EXPIRED, or CANCELLED)
     * @param page   zero-based page index (default 0)
     * @param size   page size, capped at 100 (default 20)
     * @return 200 OK with a page of {@link ReservationResponse}
     */
    @GetMapping("/history")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<Page<ReservationResponse>>> getReservationHistory(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        size = Math.min(size, 100);
        Long userId = SecurityUtils.getCurrentUserId();
        Page<ReservationResponse> history = reservationService.getReservationHistory(userId, status, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(history));
    }

    /**
     * Returns the QR code data string for the given reservation.
     *
     * <p>Verifies that the authenticated student is an accepted member of the badge that
     * owns the reservation before returning the QR code data.</p>
     *
     * @param id the ID of the reservation
     * @return 200 OK with the QR code data string
     */
    @GetMapping("/{id}/qr")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<String>> getQrCode(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        String qrCodeData = reservationService.getQrCode(id, userId);
        return ResponseEntity.ok(ApiResponse.success(qrCodeData));
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