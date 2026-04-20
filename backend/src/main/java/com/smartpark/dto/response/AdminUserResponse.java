// Response DTO for admin user management endpoints.
package com.smartpark.dto.response;

import com.smartpark.model.User;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Flat user summary returned by admin user management endpoints.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminUserResponse {

    private Long id;
    private String fullName;
    private String email;
    private String studentId;
    private String role;
    private Boolean isActive;
    private LocalDateTime createdAt;

    public static AdminUserResponse fromEntity(User user) {
        return AdminUserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .studentId(user.getStudentId())
                .role(user.getRole().name())
                .isActive(user.getIsActive())
                .createdAt(user.getCreatedAt())
                .build();
    }
}