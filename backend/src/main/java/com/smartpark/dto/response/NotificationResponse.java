// DTO for returning a single notification to the client.
package com.smartpark.dto.response;

import com.smartpark.model.Notification;

import java.time.LocalDateTime;

/**
 * Response DTO representing an in-app notification delivered to a student or guard.
 */
public class NotificationResponse {

    private Long id;
    private String notificationType;
    private String title;
    private String message;
    private boolean isRead;
    private LocalDateTime createdAt;

    private NotificationResponse() {}

    /**
     * Builds a NotificationResponse from a Notification entity.
     *
     * @param n the Notification entity
     * @return populated NotificationResponse
     */
    public static NotificationResponse fromEntity(Notification n) {
        NotificationResponse dto = new NotificationResponse();
        dto.id = n.getId();
        dto.notificationType = n.getNotificationType().name();
        dto.title = n.getTitle();
        dto.message = n.getMessage();
        dto.isRead = Boolean.TRUE.equals(n.getIsRead());
        dto.createdAt = n.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public String getNotificationType() { return notificationType; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public boolean isRead() { return isRead; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
