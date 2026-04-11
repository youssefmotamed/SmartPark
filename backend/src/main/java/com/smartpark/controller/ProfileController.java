// REST controller for student profile endpoints.
package com.smartpark.controller;

import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.BadgeDetailResponse;
import com.smartpark.dto.response.ProfileResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Exposes GET /api/v1/profile and GET /api/v1/profile/badges for authenticated students.
 */
@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    /**
     * Returns the current user's profile.
     * GET /api/v1/profile
     */
    @GetMapping
    public ResponseEntity<ApiResponse<ProfileResponse>> getProfile() {
        Long userId = SecurityUtils.getCurrentUserId();
        ProfileResponse profile = profileService.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    /**
     * Returns all badges the current user is an accepted member of.
     * GET /api/v1/profile/badges
     */
    @GetMapping("/badges")
    public ResponseEntity<ApiResponse<List<BadgeDetailResponse>>> getProfileBadges() {
        Long userId = SecurityUtils.getCurrentUserId();
        List<BadgeDetailResponse> badges = profileService.getProfileBadges(userId);
        return ResponseEntity.ok(ApiResponse.success(badges));
    }
}