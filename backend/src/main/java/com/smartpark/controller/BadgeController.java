// REST controller for badge creation and management endpoints.
package com.smartpark.controller;

import com.smartpark.dto.request.CreateBadgeRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.BadgeResponse;
import com.smartpark.service.BadgeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
}