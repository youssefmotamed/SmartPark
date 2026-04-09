// Repository for SpotOverride entity — provides audit history by spot and by guard.
package com.smartpark.repository;

import com.smartpark.model.SpotOverride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpotOverrideRepository extends JpaRepository<SpotOverride, Long> {

    List<SpotOverride> findBySpotIdOrderByCreatedAtDesc(Long spotId);

    List<SpotOverride> findByGuardIdOrderByCreatedAtDesc(Long guardId);
}