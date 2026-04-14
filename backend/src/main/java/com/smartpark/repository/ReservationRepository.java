// Repository for Reservation entity — provides QR lookup, status filtering, and expiry queries.
package com.smartpark.repository;

import com.smartpark.model.Reservation;
import com.smartpark.model.enums.ReservationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    Optional<Reservation> findByBadgeIdAndStatusIn(Long badgeId, List<ReservationStatus> statuses);

    Optional<Reservation> findByQrCodeData(String qrCodeData);

    List<Reservation> findByBadgeIdOrderByReservedAtDesc(Long badgeId);

    List<Reservation> findByStatusIn(List<ReservationStatus> statuses);

    Optional<Reservation> findBySpotIdAndStatusIn(Long spotId, List<ReservationStatus> statuses);

    Optional<Reservation> findFirstByBadgeIdAndStatusInOrderByCreatedAtDesc(Long badgeId, List<ReservationStatus> statuses);

    Optional<Reservation> findFirstByBadgeIdInAndStatusIn(List<Long> badgeIds, List<ReservationStatus> statuses);

    Page<Reservation> findByBadgeIdInAndStatusIn(List<Long> badgeIds, List<ReservationStatus> statuses, Pageable pageable);

    List<Reservation> findByStatus(ReservationStatus status);

    @Query("SELECT r FROM Reservation r JOIN FETCH r.spot WHERE r.status = :status")
    List<Reservation> findByStatusWithSpot(@NotNull ReservationStatus status);

    @Query("SELECT r FROM Reservation r WHERE r.status = 'ACTIVE' AND r.expiresAt < :now")
    List<Reservation> findExpiredReservations(@Param("now") LocalDateTime now);

    List<Reservation> findByStatusAndExpiresAtBetween(ReservationStatus status, LocalDateTime start, LocalDateTime end);
}