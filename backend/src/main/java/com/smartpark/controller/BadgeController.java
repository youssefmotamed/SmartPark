// REST controller for badge creation and management endpoints.
package com.smartpark.controller;

import com.smartpark.dto.request.AddCarRequest;
import com.smartpark.dto.request.CreateBadgeRequest;
import com.smartpark.dto.request.InviteMemberRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.BadgeReservationResponse;
import com.smartpark.dto.response.BadgeResponse;
import com.smartpark.service.BadgeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Handles badge lifecycle endpoints for students (create, invite, accept, add-car, view).
 */
@RestController
@RequestMapping("/api/v1/badges")
@RequiredArgsConstructor
public class BadgeController {

    private final BadgeService badgeService;

    /**
     * POST /api/v1/badges
     * Creates a new individual or carpool badge for the authenticated student.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<BadgeResponse>> createBadge(
            @Valid @RequestBody CreateBadgeRequest request) {
        BadgeResponse response = badgeService.createBadge(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Badge created successfully"));
    }

    /**
     * POST /api/v1/badges/{id}/invite
     * Invites a student (by studentId) to join an existing carpool badge.
     * Requires the caller to be the badge creator (canInvite=true).
     */
    @PostMapping("/{id}/invite")
    public ResponseEntity<ApiResponse<BadgeResponse>> inviteMember(
            @PathVariable Long id,
            @Valid @RequestBody InviteMemberRequest request) {
        BadgeResponse response = badgeService.inviteMember(id, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Invitation sent successfully"));
    }

    /**
     * POST /api/v1/badges/{id}/accept
     * Accepts a pending carpool badge invitation for the authenticated student.
     */
    @PostMapping("/{id}/accept")
    public ResponseEntity<ApiResponse<BadgeResponse>> acceptInvitation(@PathVariable Long id) {
        BadgeResponse response = badgeService.acceptInvitation(id);
        return ResponseEntity.ok(ApiResponse.success(response, "Invitation accepted successfully"));
    }

    /**
     * POST /api/v1/badges/{id}/add-car
     * Adds a new car plate to a badge slot for an accepted member.
     * Requires the caller to be the badge creator (canInvite=true).
     */
    @PostMapping("/{id}/add-car")
    public ResponseEntity<ApiResponse<BadgeResponse>> addCar(
            @PathVariable Long id,
            @Valid @RequestBody AddCarRequest request) {
        BadgeResponse response = badgeService.addCar(id, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Car added successfully"));
    }

    /**
     * GET /api/v1/badges/{id}
     * Returns full badge detail to any current member of the badge.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BadgeResponse>> getBadgeDetail(@PathVariable Long id) {
        BadgeResponse response = badgeService.getBadgeDetail(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * GET /api/v1/badges/{id}/reservation
     * Returns the currently active or entered reservation for the badge.
     * Caller must be an accepted member.
     */
    @GetMapping("/{id}/reservation")
    public ResponseEntity<ApiResponse<BadgeReservationResponse>> getBadgeReservation(@PathVariable Long id) {
        BadgeReservationResponse response = badgeService.getBadgeReservation(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}