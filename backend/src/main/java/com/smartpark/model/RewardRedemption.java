// Records a student's redemption of a reward, linked to the corresponding points ledger entry.
package com.smartpark.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "reward_redemptions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RewardRedemption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reward_id", nullable = false)
    private Reward reward;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "points_ledger_id", nullable = false)
    private PointsLedger pointsLedger;

    @Column(name = "redeemed_at", nullable = false)
    private LocalDateTime redeemedAt;

    /** Whether this advance-reservation token has already been consumed. */
    @Column(name = "is_used", nullable = false)
    @Builder.Default
    private boolean used = false;
}