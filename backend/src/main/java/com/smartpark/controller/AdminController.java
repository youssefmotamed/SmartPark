// REST controller for admin user management and badge management endpoints.
package com.smartpark.controller;

import com.smartpark.dto.request.CreateUserRequest;
import com.smartpark.dto.request.SuspendBadgeRequest;
import com.smartpark.dto.request.UpdateBadgeRequest;
import com.smartpark.dto.request.UpdateUserRequest;
import com.smartpark.dto.response.AdminBadgeResponse;
import com.smartpark.dto.response.AdminUserResponse;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.service.AdminService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Admin-only endpoints for managing users and badges.
 */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<Page<AdminUserResponse>>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive) {
        Page<AdminUserResponse> users = adminService.getUsers(page, size, role, search, isActive);
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @PostMapping("/users")
    public ResponseEntity<ApiResponse<AdminUserResponse>> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        AdminUserResponse user = adminService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(user, "User created"));
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<ApiResponse<AdminUserResponse>> getUserById(@PathVariable Long id) {
        AdminUserResponse user = adminService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        AdminUserResponse user = adminService.updateUser(id, request);
        return ResponseEntity.ok(ApiResponse.success(user, "User updated"));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id) {
        adminService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success(null, "User deactivated successfully"));
    }

    @GetMapping("/badges")
    public ResponseEntity<ApiResponse<Page<AdminBadgeResponse>>> getBadges(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String badgeType,
            @RequestParam(required = false) String search) {
        Page<AdminBadgeResponse> badges = adminService.getBadges(page, size, status, badgeType, search);
        return ResponseEntity.ok(ApiResponse.success(badges));
    }

    @PutMapping("/badges/{id}")
    public ResponseEntity<ApiResponse<AdminBadgeResponse>> updateBadge(
            @PathVariable Long id,
            @RequestBody UpdateBadgeRequest request) {
        AdminBadgeResponse badge = adminService.updateBadge(id, request);
        return ResponseEntity.ok(ApiResponse.success(badge, "Badge updated"));
    }

    @PostMapping("/badges/{id}/suspend")
    public ResponseEntity<ApiResponse<AdminBadgeResponse>> suspendBadge(
            @PathVariable Long id,
            @Valid @RequestBody SuspendBadgeRequest request) {
        AdminBadgeResponse badge = adminService.suspendBadge(id, request);
        return ResponseEntity.ok(ApiResponse.success(badge, "Badge suspended"));
    }

    @PostMapping("/badges/{id}/unsuspend")
    public ResponseEntity<ApiResponse<AdminBadgeResponse>> unsuspendBadge(@PathVariable Long id) {
        AdminBadgeResponse badge = adminService.unsuspendBadge(id);
        return ResponseEntity.ok(ApiResponse.success(badge, "Badge unsuspended"));
    }
}