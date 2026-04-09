// Represents a parking reservation made by a badge, tracking QR code, guard scans, and points.
package com.smartpark.model;

import com.smartpark.model.enums.ReservationStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "badge_id", nullable = false)
    private Badge badge;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "spot_id", nullable = false)
    private Spot spot;

    @Column(name = "qr_code_data", unique = true, nullable = false, length = 255)
    private String qrCodeData;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ReservationStatus status;

    @Column(name = "expected_leave_time", nullable = false)
    private LocalDateTime expectedLeaveTime;

    @Column(name = "reserved_at", nullable = false)
    private LocalDateTime reservedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "entry_scanned_at")
    private LocalDateTime entryScannedAt;

    @Column(name = "exit_scanned_at")
    private LocalDateTime exitScannedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "entry_guard_id")
    private User entryGuard;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exit_guard_id")
    private User exitGuard;

    @Column(name = "points_earned")
    private Integer pointsEarned;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}