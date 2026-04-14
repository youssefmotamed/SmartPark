// REST controller exposing notification endpoints for students and guards.
package com.smartpark.controller;

import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.NotificationResponse;
import com.smartpark.security.SecurityUtils;
import com.smartpark.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Handles retrieval and read-status management of in-app notifications.
 * Accessible to STUDENT and GUARD roles only.
 */
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Returns a paginated list of notifications for the authenticated user.
     *
     * @param unreadOnly if true, only unread notifications are returned
     * @param page       zero-based page index (default 0)
     * @param size       page size, capped at 100 (default 20)
     * @return 200 with paginated NotificationResponse list
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('STUDENT', 'GUARD')")
    public ResponseEntity<ApiResponse<Page<NotificationResponse>>> getNotifications(
            @RequestParam(defaultValue = "false") boolean unreadOnly,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        size = Math.min(size, 100);
        Long userId = SecurityUtils.getCurrentUserId();
        Page<NotificationResponse> notifications =
                notificationService.getNotifications(userId, unreadOnly, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(notifications));
    }

    /**
     * Marks the specified notification as read for the authenticated user.
     *
     * @param id notification ID
     * @return 200 on success
     */
    @PatchMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('STUDENT', 'GUARD')")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.markAsRead(id, userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /**
     * Marks all unread notifications as read for the authenticated user.
     *
     * @return 200 on success
     */
    @PatchMapping("/read-all")
    @PreAuthorize("hasAnyRole('STUDENT', 'GUARD')")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead() {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}