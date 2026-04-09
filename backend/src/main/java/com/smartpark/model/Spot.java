// Represents an individual parking spot within a zone.
package com.smartpark.model;

import com.smartpark.model.enums.SpotStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "spots")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Spot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    @Column(name = "spot_label", unique = true, nullable = false, length = 10)
    private String spotLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private SpotStatus status;

    @Column(name = "status_updated_at", nullable = false)
    private LocalDateTime statusUpdatedAt;
}