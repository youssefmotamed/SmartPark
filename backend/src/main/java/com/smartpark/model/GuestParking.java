// Represents a temporary guest parking session created by a guard for a non-registered vehicle.
package com.smartpark.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "guest_parking")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GuestParking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "spot_id", nullable = false)
    private Spot spot;

    @Column(name = "guest_plate_number", nullable = false, length = 20)
    private String guestPlateNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_guard_id", nullable = false)
    private User createdByGuard;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "purpose", columnDefinition = "TEXT")
    private String purpose;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}