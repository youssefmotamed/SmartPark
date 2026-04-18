// REST controller exposing the three student-facing points endpoints.
package com.smartpark.controller;

import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.PointsBalanceResponse;
import com.smartpark.dto.response.PointsLedgerResponse;
import com.smartpark.dto.response.PointsSummaryResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.PointsService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Provides student-facing endpoints for querying points balance, history, and summary.
 * All endpoints require the STUDENT role and derive the user ID from the JWT.
 */
@RestController
@RequestMapping("/api/v1/points")
@RequiredArgsConstructor
public class PointsController {

    private final PointsService pointsService;

    /**
     * Returns the current points balance and multiplier for the student's active badge.
     *
     * @return 200 with {@link PointsBalanceResponse}
     */
    @GetMapping("/balance")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<PointsBalanceResponse>> getBalance() {
        Long userId = SecurityUtils.getCurrentUserId();
        PointsBalanceResponse balance = pointsService.getBalance(userId);
        return ResponseEntity.ok(ApiResponse.success(balance));
    }

    /**
     * Returns a paginated points transaction history for the student's active badge.
     *
     * @param type optional filter — one of EARNED, SPENT, DIVIDED, POOLED, EXPIRED
     * @param page zero-based page index (default 0)
     * @param size page size (default 20, capped at 100)
     * @return 200 with a page of {@link PointsLedgerResponse}
     */
    @GetMapping("/history")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<Page<PointsLedgerResponse>>> getHistory(
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        size = Math.min(size, 100);
        Long userId = SecurityUtils.getCurrentUserId();
        Page<PointsLedgerResponse> history = pointsService.getHistory(userId, type, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(history));
    }

    /**
     * Returns aggregated points statistics (total earned, spent, expiring soon, current balance)
     * for the student's active badge.
     *
     * @return 200 with {@link PointsSummaryResponse}
     */
    @GetMapping("/summary")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<PointsSummaryResponse>> getSummary() {
        Long userId = SecurityUtils.getCurrentUserId();
        PointsSummaryResponse summary = pointsService.getSummary(userId);
        return ResponseEntity.ok(ApiResponse.success(summary));
    }
}