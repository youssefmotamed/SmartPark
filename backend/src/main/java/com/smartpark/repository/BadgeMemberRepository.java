// Repository for BadgeMember entity — provides carpool membership lookups and counts.
package com.smartpark.repository;

import com.smartpark.model.BadgeMember;
import com.smartpark.model.enums.BadgeMemberStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BadgeMemberRepository extends JpaRepository<BadgeMember, Long> {

    List<BadgeMember> findByUserId(Long userId);

    List<BadgeMember> findByBadgeId(Long badgeId);

    Optional<BadgeMember> findByBadgeIdAndUserId(Long badgeId, Long userId);

    boolean existsByBadgeIdAndUserId(Long badgeId, Long userId);

    long countByBadgeIdAndStatus(Long badgeId, BadgeMemberStatus status);

    List<BadgeMember> findByBadgeIdAndStatus(Long badgeId, BadgeMemberStatus status);
}