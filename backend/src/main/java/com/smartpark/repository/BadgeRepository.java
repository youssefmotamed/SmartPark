// Repository for Badge entity — provides lookup by owner and status.
package com.smartpark.repository;

import com.smartpark.model.Badge;
import com.smartpark.model.enums.BadgeStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface BadgeRepository extends JpaRepository<Badge, Long> {

    List<Badge> findByCreatedByUserId(Long userId);

    List<Badge> findByStatus(BadgeStatus status);

    @Query(value = "SELECT DISTINCT b.* FROM badges b " +
           "JOIN badge_members bm ON b.id = bm.badge_id " +
           "JOIN users u ON u.id = bm.user_id WHERE " +
           "(:status IS NULL OR b.status = :status) AND " +
           "(:badgeType IS NULL OR b.badge_type = :badgeType) AND " +
           "(:search IS NULL OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(COALESCE(u.student_id, '')) LIKE LOWER(CONCAT('%', :search, '%')))",
           countQuery = "SELECT COUNT(DISTINCT b.id) FROM badges b " +
           "JOIN badge_members bm ON b.id = bm.badge_id " +
           "JOIN users u ON u.id = bm.user_id WHERE " +
           "(:status IS NULL OR b.status = :status) AND " +
           "(:badgeType IS NULL OR b.badge_type = :badgeType) AND " +
           "(:search IS NULL OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(COALESCE(u.student_id, '')) LIKE LOWER(CONCAT('%', :search, '%')))",
           nativeQuery = true)
    Page<Badge> findWithFilters(@Param("status") String status,
                                @Param("badgeType") String badgeType,
                                @Param("search") String search,
                                Pageable pageable);

    long countByStatus(BadgeStatus status);
}