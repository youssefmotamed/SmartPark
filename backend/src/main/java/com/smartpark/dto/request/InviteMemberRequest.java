// Request DTO for inviting a student to a carpool badge.
package com.smartpark.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Payload for POST /api/v1/badges/{id}/invite.
 * Identifies the student to invite by their university student ID.
 */
@Data
public class InviteMemberRequest {

    @NotBlank(message = "Student ID is required")
    private String studentId;
}