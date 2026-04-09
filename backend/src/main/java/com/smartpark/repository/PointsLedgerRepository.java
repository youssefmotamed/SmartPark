// Repository for PointsLedger entity — provides balance calculation, transaction type filtering, and expiry queries.
package com.smartpark.repository;

import com.smartpark.model.PointsLedger;
import com.smartpark.model.enums.PointsTransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface PointsLedgerRepository extends JpaRepository<PointsLedger, Long> {

    List<PointsLedger> findByBadgeIdOrderByCreatedAtDesc(Long badgeId);

    @Query("SELECT COALESCE(SUM(p.points), 0) FROM PointsLedger p WHERE p.badge.id = :badgeId")
    int sumPointsByBadgeId(@Param("badgeId") Long badgeId);

    List<PointsLedger> findByBadgeIdAndTransactionType(Long badgeId, PointsTransactionType type);

    @Query("SELECT p FROM PointsLedger p WHERE p.expiresAt IS NOT NULL AND p.expiresAt < :now AND p.transactionType = 'EARNED'")
    List<PointsLedger> findExpiredPoints(@Param("now") LocalDateTime now);
}