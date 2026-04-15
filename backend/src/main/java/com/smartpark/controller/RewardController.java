// REST controller exposing the three student-facing reward endpoints.
package com.smartpark.controller;

import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.RedemptionHistoryResponse;
import com.smartpark.dto.response.RedemptionResponse;
import com.smartpark.dto.response.RewardResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.RewardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Provides student-facing endpoints for listing rewards, redeeming a reward,
 * and retrieving the redemption history. All endpoints require the STUDENT role
 * and derive the user ID from the JWT.
 */
@RestController
@RequestMapping("/api/v1/rewards")
@RequiredArgsConstructor
public class RewardController {

    private final RewardService rewardService;

    /**
     * Returns all rewards with an affordability flag based on the student's current balance.
     * Returns an empty list if the student has no active badge.
     *
     * @return 200 with list of {@link RewardResponse}
     */
    @GetMapping
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<List<RewardResponse>>> getRewards() {
        Long userId = SecurityUtils.getCurrentUserId();
        List<RewardResponse> rewards = rewardService.getRewards(userId);
        return ResponseEntity.ok(ApiResponse.success(rewards));
    }

    /**
     * Redeems the specified reward, deducting points from the student's active badge.
     *
     * @param id the reward ID to redeem
     * @return 200 with {@link RedemptionResponse} confirming the transaction
     */
    @PostMapping("/{id}/redeem")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<RedemptionResponse>> redeemReward(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        RedemptionResponse response = rewardService.redeemReward(id, userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * Returns the student's full reward redemption history, ordered by most recent first.
     *
     * @return 200 with list of {@link RedemptionHistoryResponse}
     */
    @GetMapping("/redemptions")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<List<RedemptionHistoryResponse>>> getRedemptionHistory() {
        Long userId = SecurityUtils.getCurrentUserId();
        List<RedemptionHistoryResponse> history = rewardService.getRedemptionHistory(userId);
        return ResponseEntity.ok(ApiResponse.success(history));
    }
}