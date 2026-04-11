// Response DTO for the registration endpoint — confirms the created user's identity and role.
package com.smartpark.dto.response;

public class RegisterResponse {

    private Long userId;
    private String studentId;
    private String role;

    public RegisterResponse(Long userId, String studentId, String role) {
        this.userId = userId;
        this.studentId = studentId;
        this.role = role;
    }

    public Long getUserId() { return userId; }
    public String getStudentId() { return studentId; }
    public String getRole() { return role; }
}