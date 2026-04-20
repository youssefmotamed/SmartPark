// Request DTO for admin updating a user's name and email.
package com.smartpark.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateUserRequest {

    @NotBlank
    private String fullName;

    @NotBlank
    @Email
    private String email;
}