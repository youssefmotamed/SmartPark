// REST controller for authentication endpoints — register, login, and token refresh.
package com.smartpark.controller;

import com.smartpark.dto.request.LoginRequest;
import com.smartpark.dto.request.RefreshTokenRequest;
import com.smartpark.dto.request.RegisterRequest;
import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.AuthResponse;
import com.smartpark.dto.response.RegisterResponse;
import com.smartpark.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Handles public auth routes: /api/v1/auth/register, /login, and /refresh.
 * All endpoints are permit-all in SecurityConfig.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<RegisterResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        RegisterResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Registration successful"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Login successful"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refresh(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}