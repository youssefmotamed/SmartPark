// Request DTO for student registration — carries user info and plate number for badge/car creation.
package com.smartpark.dto.request;

import jakarta.validation.constraints.*;

public class RegisterRequest {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Student ID is required")
    private String studentId;

    @Email(message = "Must be a valid email address")
    @NotBlank(message = "Email is required")
    private String email;

    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;

    @NotBlank(message = "Plate number is required")
    private String plateNumber;

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getPlateNumber() { return plateNumber; }
    public void setPlateNumber(String plateNumber) { this.plateNumber = plateNumber; }
}
