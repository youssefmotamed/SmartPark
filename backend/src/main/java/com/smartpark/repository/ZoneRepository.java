// Repository for Zone entity — provides lookup by zone code.
package com.smartpark.repository;

import com.smartpark.model.Zone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ZoneRepository extends JpaRepository<Zone, Long> {

    Optional<Zone> findByZoneCode(String zoneCode);
}