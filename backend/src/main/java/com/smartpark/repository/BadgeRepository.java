// Repository for Badge entity — provides lookup by owner and status.
package com.smartpark.repository;

import com.smartpark.model.Badge;
import com.smartpark.model.enums.BadgeStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BadgeRepository extends JpaRepository<Badge, Long> {

    List<Badge> findByCreatedByUserId(Long userId);

    List<Badge> findByStatus(BadgeStatus status);
}