// Records a manual spot status override performed by a guard (e.g. correcting a camera error).
package com.smartpark.model;

import com.smartpark.model.enums.OverrideReason;
import com.smartpark.model.enums.SpotStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "spot_overrides")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SpotOverride {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "spot_id", nullable = false)
    private Spot spot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "guard_id", nullable = false)
    private User guard;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status", nullable = false)
    private SpotStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false)
    private SpotStatus newStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "reason", nullable = false)
    private OverrideReason reason;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}