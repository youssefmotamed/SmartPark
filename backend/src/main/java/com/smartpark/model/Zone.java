// Represents a parking zone on campus with an access restriction type.
package com.smartpark.model;

import com.smartpark.model.enums.ZoneAccessType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "zones")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Zone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "zone_code", unique = true, nullable = false, length = 5)
    private String zoneCode;

    @Column(name = "zone_name", nullable = false, length = 50)
    private String zoneName;

    @Enumerated(EnumType.STRING)
    @Column(name = "access_type", nullable = false)
    private ZoneAccessType accessType;
}