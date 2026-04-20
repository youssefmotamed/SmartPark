// Service for reporting parking violations and applying badge suspensions.
package com.smartpark.service;

import com.smartpark.dto.request.ReportViolationRequest;
import com.smartpark.dto.response.ViolationResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.Reservation;
import com.smartpark.model.Spot;
import com.smartpark.model.User;
import com.smartpark.model.Violation;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.model.enums.ViolationType;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.UserRepository;
import com.smartpark.repository.ViolationRepository;
import com.smartpark.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Handles violation reporting by guards. Suspends the offending badge,
 * cancels any active reservation, and notifies all accepted members.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class ViolationService {

    private static final Logger log = LoggerFactory.getLogger(ViolationService.class);

    private final BadgeCarRepository badgeCarRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final BadgeRepository badgeRepository;
    private final ReservationRepository reservationRepository;
    private final SpotRepository spotRepository;
    private final UserRepository userRepository;
    private final ViolationRepository violationRepository;
    private final NotificationService notificationService;

    /**
     * Reports a parking violation for the badge associated with the given plate number.
     * Suspends the badge, cancels any active reservation, and notifies affected members.
     *
     * @param request plate number, violation type, and optional notes
     * @return ViolationResponse with suspension details and affected student names
     */
    public ViolationResponse reportViolation(ReportViolationRequest request) {
        Long guardId = SecurityUtils.getCurrentUserId();

        BadgeCar badgeCar = badgeCarRepository.findFirstByPlateNumber(request.getPlateNumber())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No badge found for plate number: " + request.getPlateNumber()));

        Badge badge = badgeCar.getBadge();

        ViolationType violationType;
        try {
            violationType = ViolationType.valueOf(request.getViolationType());
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("INVALID_VIOLATION_TYPE", "Invalid violation type");
        }

        int suspensionDays = switch (badge.getViolationCount()) {
            case 0 -> 1;
            case 1 -> 3;
            default -> 7;
        };

        badge.setStatus(BadgeStatus.SUSPENDED);
        badge.setSuspendedUntil(LocalDateTime.now().plusDays(suspensionDays));
        badge.setSuspensionReason(violationType.name());
        badge.setViolationCount(badge.getViolationCount() + 1);
        badgeRepository.save(badge);

        User guard = userRepository.findById(guardId)
                .orElseThrow(() -> new ResourceNotFoundException("Guard not found: " + guardId));

        Violation violation = Violation.builder()
                .badge(badge)
                .plateNumber(request.getPlateNumber())
                .violationType(violationType)
                .reportedByGuard(guard)
                .suspensionDays(suspensionDays)
                .notes(request.getNotes())
                .build();
        violation = violationRepository.save(violation);

        List<BadgeMember> acceptedMembers = badgeMemberRepository
                .findByBadgeIdAndStatus(badge.getId(), BadgeMemberStatus.ACCEPTED);

        String notifMessage = "Your badge has been suspended for " + suspensionDays
                + " day(s) due to a parking violation. Suspended until: " + badge.getSuspendedUntil();

        for (BadgeMember member : acceptedMembers) {
            notificationService.createNotification(
                    member.getUser().getId(),
                    NotificationType.SUSPENSION,
                    "Badge Suspended",
                    notifMessage);
        }

        Optional<Reservation> activeReservation = reservationRepository
                .findFirstByBadgeIdAndStatusInOrderByCreatedAtDesc(
                        badge.getId(),
                        List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED));

        if (activeReservation.isPresent()) {
            Reservation reservation = activeReservation.get();
            reservation.setStatus(ReservationStatus.CANCELLED);

            Spot spot = reservation.getSpot();
            spot.setStatus(SpotStatus.AVAILABLE);
            spot.setStatusUpdatedAt(LocalDateTime.now());
            spotRepository.save(spot);

            reservationRepository.save(reservation);
        }

        List<String> affectedStudents = acceptedMembers.stream()
                .map(m -> m.getUser().getFullName())
                .collect(Collectors.toList());

        log.warn("Badge {} suspended for {} day(s) — plate: {}, guard: {}",
                badge.getId(), suspensionDays, request.getPlateNumber(), guardId);

        return ViolationResponse.builder()
                .violationId(violation.getId())
                .badgeId(badge.getId())
                .badgeType(badge.getBadgeType().name())
                .suspensionDays(suspensionDays)
                .suspendedUntil(badge.getSuspendedUntil())
                .affectedStudents(affectedStudents)
                .build();
    }
}