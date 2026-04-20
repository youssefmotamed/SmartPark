// Repository for BadgeCar entity — provides car lookups by badge and plate number.
package com.smartpark.repository;

import com.smartpark.model.BadgeCar;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BadgeCarRepository extends JpaRepository<BadgeCar, Long> {

    List<BadgeCar> findByBadgeId(Long badgeId);

    Optional<BadgeCar> findFirstByPlateNumber(String plateNumber);

    Optional<BadgeCar> findByBadgeIdAndPlateNumber(Long badgeId, String plateNumber);

    long countByBadgeId(Long badgeId);

    /** Returns the first car ever registered by this user across all badges (oldest by id). */
    Optional<BadgeCar> findFirstByUserIdOrderByIdAsc(Long userId);

    boolean existsByBadgeIdAndPlateNumber(Long badgeId, String plateNumber);
}