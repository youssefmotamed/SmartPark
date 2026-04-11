// Response DTO for login and refresh endpoints — contains JWT tokens and basic user info.
package com.smartpark.dto.response;

public class AuthResponse {

    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private long expiresIn;
    private UserInfo user;

    public AuthResponse(String accessToken, String refreshToken, UserInfo user) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.tokenType = "Bearer";
        this.expiresIn = 3600;
        this.user = user;
    }

    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
    public String getTokenType() { return tokenType; }
    public long getExpiresIn() { return expiresIn; }
    public UserInfo getUser() { return user; }

    public static class UserInfo {
        private Long id;
        private String fullName;
        private String role;

        public UserInfo(Long id, String fullName, String role) {
            this.id = id;
            this.fullName = fullName;
            this.role = role;
        }

        public Long getId() { return id; }
        public String getFullName() { return fullName; }
        public String getRole() { return role; }
    }
}