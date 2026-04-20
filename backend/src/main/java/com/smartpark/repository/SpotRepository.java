// Repository for Spot entity — provides lookups by zone, status, and label.
package com.smartpark.repository;

import com.smartpark.model.Spot;
import com.smartpark.model.enums.SpotStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpotRepository extends JpaRepository<Spot, Long> {

    List<Spot> findByZoneId(Long zoneId);

    List<Spot> findByStatus(SpotStatus status);

    Optional<Spot> findBySpotLabel(String spotLabel);

    long countByStatus(SpotStatus status);
}