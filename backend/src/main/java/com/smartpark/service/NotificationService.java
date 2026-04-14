// Service for creating and managing in-app notifications for students and guards.
package com.smartpark.service;

import com.smartpark.dto.response.NotificationResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Notification;
import com.smartpark.model.User;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.repository.NotificationRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Manages creation, retrieval, and read-status of in-app notifications.
 * Intended to be injected by other services (ReservationService, GateService, etc.)
 * to deliver notifications as a side effect of domain operations.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    /**
     * Creates and persists a notification for the given user ID.
     * Uses getReferenceById to avoid a redundant SELECT when only the FK is needed.
     *
     * @param userId  target user's ID
     * @param type    notification category
     * @param title   short heading shown in the notification list
     * @param message full notification body text
     * @return the saved Notification entity
     */
    public Notification createNotification(Long userId, NotificationType type, String title, String message) {
        User userRef = userRepository.getReferenceById(userId);
        Notification notification = Notification.builder()
                .user(userRef)
                .notificationType(type)
                .title(title)
                .message(message)
                .isRead(false)
                .build();
        Notification saved = notificationRepository.save(notification);
        log.info("Notification created for user {}: {}", userId, title);
        return saved;
    }

    /**
     * Creates and persists a notification when the caller already holds the User entity.
     * Avoids a getReferenceById call in hot paths where the User is already loaded.
     *
     * @param user    target User entity
     * @param type    notification category
     * @param title   short heading shown in the notification list
     * @param message full notification body text
     * @return the saved Notification entity
     */
    public Notification createNotificationForUser(User user, NotificationType type, String title, String message) {
        Notification notification = Notification.builder()
                .user(user)
                .notificationType(type)
                .title(title)
                .message(message)
                .isRead(false)
                .build();
        Notification saved = notificationRepository.save(notification);
        log.info("Notification created for user {}: {}", user.getId(), title);
        return saved;
    }

    /**
     * Returns a paginated list of notifications for the given user.
     *
     * @param userId     target user's ID
     * @param unreadOnly if true, returns only unread notifications
     * @param pageable   pagination and sorting config
     * @return page of NotificationResponse DTOs ordered by createdAt DESC
     */
    @Transactional(readOnly = true)
    public Page<NotificationResponse> getNotifications(Long userId, boolean unreadOnly, Pageable pageable) {
        Page<Notification> page = unreadOnly
                ? notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId, pageable)
                : notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        return page.map(NotificationResponse::fromEntity);
    }

    /**
     * Marks a single notification as read. Verifies ownership before updating.
     *
     * @param notificationId ID of the notification to mark as read
     * @param userId         ID of the requesting user (must match notification owner)
     * @throws ResourceNotFoundException if the notification does not exist
     * @throws BusinessRuleException     if the notification belongs to a different user
     */
    public void markAsRead(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found: " + notificationId));

        if (!notification.getUser().getId().equals(userId)) {
            throw new BusinessRuleException("ACCESS_DENIED", "This notification does not belong to you");
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    /**
     * Marks all unread notifications belonging to the given user as read.
     *
     * @param userId target user's ID
     */
    public void markAllAsRead(Long userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndIsReadFalse(userId);
        unread.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unread);
        log.info("Marked {} notifications as read for user {}", unread.size(), userId);
    }
}