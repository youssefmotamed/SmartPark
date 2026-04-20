// Repository for Violation entity — provides badge violation history and recent count queries.
package com.smartpark.repository;

import com.smartpark.model.Violation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ViolationRepository extends JpaRepository<Violation, Long> {

    List<Violation> findByBadgeId(Long badgeId);

    @Query("SELECT COUNT(v) FROM Violation v WHERE v.badge.id = :badgeId AND v.createdAt >= :since")
    long countByBadgeIdAndCreatedAtAfter(@Param("badgeId") Long badgeId, @Param("since") LocalDateTime since);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    Page<Violation> findAllByOrderByCreatedAtDesc(Pageable pageable);
}