// Request DTO for token refresh — carries the existing refresh token to exchange for new tokens.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;

public class RefreshTokenRequest {

    @NotBlank(message = "Refresh token is required")
    private String refreshToken;

    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
}