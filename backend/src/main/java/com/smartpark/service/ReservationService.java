// Service for creating and managing parking reservations with full validation chain.
package com.smartpark.service;

import com.smartpark.dto.request.CreateReservationRequest;
import com.smartpark.dto.response.ReservationResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.Reservation;
import com.smartpark.model.Spot;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.BadgeType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.model.enums.ZoneAccessType;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Handles reservation creation with an ordered validation chain covering badge ownership,
 * suspension state, spot availability, zone access, geolocation, and same-spot restrictions.
 */
@Service
@RequiredArgsConstructor
public class ReservationService {

    private static final Logger log = LoggerFactory.getLogger(ReservationService.class);

    private static final double CAMPUS_LAT = 31.2156;
    private static final double CAMPUS_LNG = 29.9553;
    private static final double MAX_DISTANCE_KM = 5.0;

    @Value("${app.debug.skip-geolocation:false}")
    private boolean skipGeolocation;

    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final SpotRepository spotRepository;
    private final ReservationRepository reservationRepository;
    private final UserRepository userRepository;

    /**
     * Creates a new parking reservation after running all validation checks in order.
     *
     * @param userId  ID of the authenticated student making the request
     * @param request validated request body carrying spotId, badgeId, location, and expected leave time
     * @return a {@link ReservationResponse} for the newly created reservation
     */
    @Transactional
    public ReservationResponse createReservation(Long userId, CreateReservationRequest request) {

        // 1. Badge existence and ownership
        Badge badge = badgeRepository.findById(request.getBadgeId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Badge with ID " + request.getBadgeId() + " not found"));

        Optional<BadgeMember> membership = badgeMemberRepository
                .findByBadgeIdAndUserId(badge.getId(), userId);
        if (membership.isEmpty() || membership.get().getStatus() != BadgeMemberStatus.ACCEPTED) {
            log.warn("User {} attempted to use badge {} without accepted membership", userId, badge.getId());
            throw new BusinessRuleException("BADGE_ACCESS_DENIED", "This badge does not belong to you");
        }

        // 2. Badge active status
        if (badge.getStatus() != BadgeStatus.ACTIVE) {
            log.warn("User {} attempted to reserve with inactive badge {}", userId, badge.getId());
            throw new BusinessRuleException("BADGE_INACTIVE", "Your badge is not active");
        }

        // 3. Suspension check
        if (badge.getSuspendedUntil() != null && badge.getSuspendedUntil().isAfter(LocalDateTime.now())) {
            log.warn("User {} attempted to reserve with suspended badge {} (until {})",
                    userId, badge.getId(), badge.getSuspendedUntil());
            throw new BusinessRuleException("BADGE_SUSPENDED",
                    "Your badge is suspended until " + badge.getSuspendedUntil());
        }

        // 4. No existing active reservation on this badge
        Optional<Reservation> existing = reservationRepository.findByBadgeIdAndStatusIn(
                badge.getId(), List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED));
        if (existing.isPresent()) {
            log.warn("User {} attempted to create duplicate reservation on badge {}", userId, badge.getId());
            throw new BusinessRuleException("RESERVATION_EXISTS", "This badge already has an active reservation");
        }

        // 5. Spot existence and availability
        Spot spot = spotRepository.findById(request.getSpotId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Spot with ID " + request.getSpotId() + " not found"));

        if (spot.getStatus() != SpotStatus.AVAILABLE) {
            log.warn("User {} attempted to reserve unavailable spot {} (status={})",
                    userId, spot.getSpotLabel(), spot.getStatus());
            throw new BusinessRuleException("SPOT_NOT_AVAILABLE", "This spot is not currently available");
        }

        // 6. Zone access check
        ZoneAccessType zoneAccess = spot.getZone().getAccessType();
        if (zoneAccess == ZoneAccessType.CARPOOL_ONLY && badge.getBadgeType() == BadgeType.INDIVIDUAL) {
            log.warn("User {} attempted to reserve carpool-only spot {} with individual badge",
                    userId, spot.getSpotLabel());
            throw new BusinessRuleException("ZONE_ACCESS_DENIED", "Zone B is for carpool badges only");
        }
        if (zoneAccess == ZoneAccessType.GUARD_ONLY) {
            log.warn("User {} attempted to reserve guard-only spot {}", userId, spot.getSpotLabel());
            throw new BusinessRuleException("ZONE_ACCESS_DENIED", "Zone C is for guest parking only");
        }

        // 7. Geolocation check
        if (!skipGeolocation && !isWithinCampus(request.getLatitude(), request.getLongitude())) {
            log.warn("User {} is too far from campus to reserve (lat={}, lng={})",
                    userId, request.getLatitude(), request.getLongitude());
            throw new BusinessRuleException("TOO_FAR", "You must be near campus to make a reservation");
        }

        // 8. Same-spot restriction
        Optional<Reservation> lastReservation = reservationRepository
                .findFirstByBadgeIdAndStatusInOrderByCreatedAtDesc(
                        badge.getId(), List.of(ReservationStatus.EXPIRED, ReservationStatus.CANCELLED));
        if (lastReservation.isPresent() && lastReservation.get().getSpot().getId().equals(spot.getId())) {
            log.warn("User {} attempted to re-reserve same spot {} after expiry/cancellation",
                    userId, spot.getSpotLabel());
            throw new BusinessRuleException("SAME_SPOT_RESTRICTION",
                    "You cannot reserve the same spot you just left");
        }

        // Build and persist reservation
        String qrCodeData = "SP-RES-" + UUID.randomUUID().toString().replace("-", "")
                .substring(0, 8).toUpperCase();

        Reservation reservation = Reservation.builder()
                .badge(badge)
                .user(userRepository.getReferenceById(userId))
                .spot(spot)
                .qrCodeData(qrCodeData)
                .status(ReservationStatus.ACTIVE)
                .reservedAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .expectedLeaveTime(request.getExpectedLeaveTime())
                .build();

        reservation = reservationRepository.save(reservation);

        // Update spot status
        spot.setStatus(SpotStatus.RESERVED);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);

        log.info("Reservation created: id={}, spot={}, badge={}, user={}",
                reservation.getId(), spot.getSpotLabel(), badge.getId(), userId);

        return ReservationResponse.fromEntity(reservation);
    }

    /**
     * Cancels an active reservation owned by the given user.
     *
     * @param reservationId ID of the reservation to cancel
     * @param userId        ID of the authenticated student making the request
     */
    @Transactional
    public void cancelReservation(Long reservationId, Long userId) {
        // 1. Find reservation
        Reservation reservation = reservationRepository.findById(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Reservation with ID " + reservationId + " not found"));

        // 2. Verify ownership via badge membership
        Optional<BadgeMember> membership = badgeMemberRepository
                .findByBadgeIdAndUserId(reservation.getBadge().getId(), userId);
        if (membership.isEmpty() || membership.get().getStatus() != BadgeMemberStatus.ACCEPTED) {
            throw new BusinessRuleException("ACCESS_DENIED", "You do not own this reservation");
        }

        // 3. Check status is ACTIVE
        if (reservation.getStatus() != ReservationStatus.ACTIVE) {
            throw new BusinessRuleException("CANNOT_CANCEL",
                    "Only active reservations can be cancelled. Current status: " + reservation.getStatus());
        }

        // 4. Cancel reservation
        reservation.setStatus(ReservationStatus.CANCELLED);
        reservationRepository.save(reservation);

        // 5. Free the spot
        Spot spot = reservation.getSpot();
        spot.setStatus(SpotStatus.AVAILABLE);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);

        log.info("Reservation {} cancelled by user {}", reservationId, userId);
    }

    /**
     * Returns true if the given coordinates are within {@code MAX_DISTANCE_KM} of campus
     * using the Haversine formula.
     */
    private boolean isWithinCampus(double userLat, double userLng) {
        double dLat = Math.toRadians(CAMPUS_LAT - userLat);
        double dLng = Math.toRadians(CAMPUS_LNG - userLng);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(userLat)) * Math.cos(Math.toRadians(CAMPUS_LAT))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = 6371 * c;
        return distance <= MAX_DISTANCE_KM;
    }
}