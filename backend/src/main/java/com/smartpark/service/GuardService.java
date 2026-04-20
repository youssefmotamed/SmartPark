// Service handling guard operations: guest parking, spot overrides, and active reservation listing.
package com.smartpark.service;

import com.smartpark.dto.request.CreateGuestParkingRequest;
import com.smartpark.dto.request.SpotOverrideRequest;
import com.smartpark.dto.response.GuestParkingResponse;
import com.smartpark.dto.response.GuardReservationResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.GuestParking;
import com.smartpark.model.Spot;
import com.smartpark.model.SpotOverride;
import com.smartpark.model.User;
import com.smartpark.model.enums.OverrideReason;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.model.enums.ZoneAccessType;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.GuestParkingRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.SpotOverrideRepository;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.UserRepository;
import com.smartpark.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Business logic for all guard-specific operations.
 */
@Service
@RequiredArgsConstructor
public class GuardService {

    private static final Logger log = LoggerFactory.getLogger(GuardService.class);

    private final SpotRepository spotRepository;
    private final GuestParkingRepository guestParkingRepository;
    private final SpotOverrideRepository spotOverrideRepository;
    private final ReservationRepository reservationRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final UserRepository userRepository;

    /**
     * Creates a guest parking session in a Zone C spot (GUARD_ONLY).
     * Sets spot status to OCCUPIED.
     */
    @Transactional
    public GuestParkingResponse createGuestParking(CreateGuestParkingRequest request) {
        Long guardId = SecurityUtils.getCurrentUserId();

        Spot spot = spotRepository.findById(request.getSpotId())
                .orElseThrow(() -> new ResourceNotFoundException("Spot not found"));

        if (spot.getZone().getAccessType() != ZoneAccessType.GUARD_ONLY) {
            throw new BusinessRuleException("NOT_ZONE_C", "Guest parking is only allowed in Zone C");
        }

        if (spot.getStatus() != SpotStatus.AVAILABLE) {
            throw new BusinessRuleException("SPOT_NOT_AVAILABLE", "This spot is not available");
        }

        User guard = userRepository.getReferenceById(guardId);

        GuestParking guestParking = GuestParking.builder()
                .spot(spot)
                .guestPlateNumber(request.getGuestPlateNumber())
                .purpose(request.getPurpose())
                .status("ACTIVE")
                .createdByGuard(guard)
                .build();

        guestParking = guestParkingRepository.save(guestParking);

        spot.setStatus(SpotStatus.OCCUPIED);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);

        log.info("Guest parking created: spot {}, plate {}, guard {}", spot.getSpotLabel(), request.getGuestPlateNumber(), guardId);

        return GuestParkingResponse.fromEntity(guestParking);
    }

    /**
     * Marks a guest parking session as COMPLETED and frees the spot.
     */
    @Transactional
    public GuestParkingResponse completeGuestParking(Long guestParkingId) {
        GuestParking guestParking = guestParkingRepository.findById(guestParkingId)
                .orElseThrow(() -> new ResourceNotFoundException("Guest parking entry not found"));

        if (!"ACTIVE".equals(guestParking.getStatus())) {
            throw new BusinessRuleException("NOT_ACTIVE", "This guest parking entry is not active");
        }

        guestParking.setStatus("COMPLETED");
        guestParking.setCompletedAt(LocalDateTime.now());
        guestParkingRepository.save(guestParking);

        Spot spot = guestParking.getSpot();
        spot.setStatus(SpotStatus.AVAILABLE);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);

        log.info("Guest parking {} completed", guestParkingId);

        return GuestParkingResponse.fromEntity(guestParking);
    }

    /**
     * Manually overrides a spot's status and records the audit entry in spot_overrides.
     */
    @Transactional
    public void overrideSpotStatus(Long spotId, SpotOverrideRequest request) {
        Long guardId = SecurityUtils.getCurrentUserId();

        Spot spot = spotRepository.findById(spotId)
                .orElseThrow(() -> new ResourceNotFoundException("Spot not found"));

        SpotStatus newStatus;
        try {
            newStatus = SpotStatus.valueOf(request.getNewStatus());
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("INVALID_STATUS", "Invalid spot status");
        }

        OverrideReason reason;
        try {
            reason = OverrideReason.valueOf(request.getReason());
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("INVALID_REASON", "Invalid override reason");
        }

        User guard = userRepository.getReferenceById(guardId);

        SpotOverride override = SpotOverride.builder()
                .spot(spot)
                .guard(guard)
                .previousStatus(spot.getStatus())
                .newStatus(newStatus)
                .reason(reason)
                .build();

        spotOverrideRepository.save(override);

        log.info("Spot {} overridden: {} -> {} by guard {}", spot.getSpotLabel(), override.getPreviousStatus(), newStatus, guardId);

        spot.setStatus(newStatus);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);
    }

    /**
     * Returns all currently active student reservations (ACTIVE + ENTERED) and active guest parking sessions.
     * Reservations appear first, guest sessions after.
     */
    public List<GuardReservationResponse> getActiveReservations() {
        List<GuardReservationResponse> result = new ArrayList<>();

        List<ReservationStatus> activeStatuses = List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED);
        reservationRepository.findByStatusIn(activeStatuses).forEach(reservation -> {
            List<String> plates = badgeCarRepository.findByBadgeId(reservation.getBadge().getId())
                    .stream()
                    .map(car -> car.getPlateNumber())
                    .collect(Collectors.toList());

            result.add(GuardReservationResponse.builder()
                    .type("RESERVATION")
                    .id(reservation.getId())
                    .spotLabel(reservation.getSpot().getSpotLabel())
                    .zoneCode(reservation.getSpot().getZone().getZoneCode())
                    .studentName(reservation.getBadge().getCreatedByUser().getFullName())
                    .badgeType(reservation.getBadge().getBadgeType().toString())
                    .status(reservation.getStatus().toString())
                    .reservedAt(reservation.getReservedAt())
                    .expectedLeaveTime(reservation.getExpectedLeaveTime())
                    .plateNumbers(plates)
                    .build());
        });

        guestParkingRepository.findByStatus("ACTIVE").forEach(gp -> {
            result.add(GuardReservationResponse.builder()
                    .type("GUEST")
                    .id(gp.getId())
                    .spotLabel(gp.getSpot().getSpotLabel())
                    .zoneCode(gp.getSpot().getZone().getZoneCode())
                    .guestPlateNumber(gp.getGuestPlateNumber())
                    .purpose(gp.getPurpose())
                    .guardId(gp.getCreatedByGuard().getId())
                    .createdAt(gp.getCreatedAt())
                    .build());
        });

        return result;
    }
}