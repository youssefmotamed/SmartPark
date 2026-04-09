// Represents a parking badge (individual or carpool group) that holds points and reservation rights.
package com.smartpark.model;

import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.BadgeType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "badges")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Badge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "badge_type", nullable = false)
    private BadgeType badgeType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private BadgeStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_user_id", nullable = false)
    private User createdByUser;

    @Column(name = "max_slots", nullable = false)
    private Integer maxSlots;

    @Column(name = "points_balance", nullable = false)
    private Integer pointsBalance;

    @Column(name = "semester_number", nullable = false)
    private Integer semesterNumber;

    @Column(name = "semester_year", nullable = false)
    private Integer semesterYear;

    @Column(name = "violation_count", nullable = false)
    private Integer violationCount;

    @Column(name = "suspended_until")
    private LocalDateTime suspendedUntil;

    @Column(name = "suspension_reason", length = 255)
    private String suspensionReason;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}