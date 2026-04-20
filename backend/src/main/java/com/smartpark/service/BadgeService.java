// Business logic for badge creation and management.
package com.smartpark.service;

import com.smartpark.dto.request.AddCarRequest;
import com.smartpark.dto.request.CreateBadgeRequest;
import com.smartpark.dto.request.InviteMemberRequest;
import com.smartpark.dto.response.BadgeReservationResponse;
import com.smartpark.dto.response.BadgeResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.Reservation;
import com.smartpark.model.User;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.BadgeType;
import com.smartpark.model.enums.NotificationType;
import com.smartpark.model.enums.ReservationStatus;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.ReservationRepository;
import com.smartpark.repository.UserRepository;
import com.smartpark.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service handling badge creation and badge-level queries.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class BadgeService {

    private static final Logger log = LoggerFactory.getLogger(BadgeService.class);

    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final UserRepository userRepository;
    private final ReservationRepository reservationRepository;
    private final NotificationService notificationService;

    /**
     * Creates a new parking badge for the currently authenticated student.
     * Saves Badge, BadgeMember, and BadgeCar in a single transaction.
     *
     * @param request badge type and semester details
     * @return full badge detail response
     */
    public BadgeResponse createBadge(CreateBadgeRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Parse and validate badge type
        BadgeType badgeType;
        try {
            badgeType = BadgeType.valueOf(request.getBadgeType());
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("INVALID_BADGE_TYPE", "Invalid badge type");
        }

        int maxSlots = switch (badgeType) {
            case INDIVIDUAL -> 1;
            case CARPOOL_2 -> 2;
            case CARPOOL_3 -> 3;
            case CARPOOL_4 -> 4;
            case CARPOOL_5 -> 5;
        };

        LocalDateTime expiresAt = calculateExpiresAt(request.getSemesterNumber(), request.getSemesterYear());

        // Build and save Badge
        Badge badge = Badge.builder()
                .badgeType(badgeType)
                .status(BadgeStatus.ACTIVE)
                .createdByUser(user)
                .maxSlots(maxSlots)
                .pointsBalance(0)
                .semesterNumber(request.getSemesterNumber())
                .semesterYear(request.getSemesterYear())
                .violationCount(0)
                .expiresAt(expiresAt)
                .build();
        badge = badgeRepository.save(badge);

        // Build and save BadgeMember for the creator
        BadgeMember member = BadgeMember.builder()
                .badge(badge)
                .user(user)
                .status(BadgeMemberStatus.ACCEPTED)
                .canInvite(true)
                .joinedAt(LocalDateTime.now())
                .build();
        badgeMemberRepository.save(member);

        // Copy the creator's existing car to the new badge
        BadgeCar existingCar = badgeCarRepository.findFirstByUserIdOrderByIdAsc(userId)
                .orElseThrow(() -> new BusinessRuleException("NO_CAR_REGISTERED",
                        "No car registered for your account"));

        BadgeCar badgeCar = BadgeCar.builder()
                .badge(badge)
                .user(user)
                .plateNumber(existingCar.getPlateNumber())
                .carModel(existingCar.getCarModel())
                .build();
        badgeCarRepository.save(badgeCar);

        log.info("Badge {} of type {} created by user {}", badge.getId(), badgeType, userId);

        return buildResponse(badge, List.of(member), List.of(badgeCar));
    }

    /**
     * Invites a student to an existing carpool badge.
     * Only the badge creator (canInvite=true) may send invitations.
     * A BadgeMember record (PENDING) and a BadgeCar record are saved in the same transaction.
     *
     * @param badgeId ID of the badge to invite into
     * @param request contains the studentId of the user to invite
     * @return updated badge detail response
     */
    public BadgeResponse inviteMember(Long badgeId, InviteMemberRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        // Verify caller has permission to invite
        BadgeMember callerMember = badgeMemberRepository.findByBadgeIdAndUserId(badgeId, currentUserId)
                .orElseThrow(() -> new BusinessRuleException("NOT_BADGE_CREATOR",
                        "You do not have permission to invite members to this badge"));
        if (!callerMember.getCanInvite()) {
            throw new BusinessRuleException("NOT_BADGE_CREATOR",
                    "You do not have permission to invite members to this badge");
        }

        // Check available slots (one BadgeCar per member)
        long carCount = badgeCarRepository.countByBadgeId(badgeId);
        if (carCount >= badge.getMaxSlots()) {
            throw new BusinessRuleException("NO_SLOTS_AVAILABLE", "All slots for this badge are filled");
        }

        // Resolve invited student by university student ID
        User invitedUser = userRepository.findByStudentId(request.getStudentId())
                .orElseThrow(() -> new ResourceNotFoundException("Student not found"));

        // Guard against duplicate invitations
        if (badgeMemberRepository.existsByBadgeIdAndUserId(badgeId, invitedUser.getId())) {
            throw new BusinessRuleException("ALREADY_INVITED",
                    "This student has already been invited to this badge");
        }

        // Invited student must already have a car registered
        BadgeCar invitedCar = badgeCarRepository.findFirstByUserIdOrderByIdAsc(invitedUser.getId())
                .orElseThrow(() -> new BusinessRuleException("INVITED_USER_NO_CAR",
                        "The invited student has no registered car"));

        // Create BadgeMember (PENDING)
        BadgeMember newMember = BadgeMember.builder()
                .badge(badge)
                .user(invitedUser)
                .status(BadgeMemberStatus.PENDING)
                .canInvite(false)
                .joinedAt(null)
                .build();
        badgeMemberRepository.save(newMember);

        // Register invited student's car on this badge
        BadgeCar badgeCar = BadgeCar.builder()
                .badge(badge)
                .user(invitedUser)
                .plateNumber(invitedCar.getPlateNumber())
                .carModel(invitedCar.getCarModel())
                .build();
        badgeCarRepository.save(badgeCar);

        User inviter = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Inviter not found"));
        String inviterFullName = inviter.getFullName();
        notificationService.createNotification(invitedUser.getId(), NotificationType.CARPOOL_INVITE,
                "Carpool Invitation", "You have been invited to join a carpool badge by " + inviterFullName + ". Badge ID: " + badgeId + ", Badge Type: " + badge.getBadgeType());

        log.info("Badge {} invitation sent to user {} by user {}", badgeId, invitedUser.getId(), currentUserId);

        return buildResponseFromDb(badge);
    }

    /**
     * Accepts a pending carpool badge invitation for the currently authenticated student.
     *
     * @param badgeId ID of the badge whose invitation to accept
     * @return updated badge detail response
     */
    public BadgeResponse acceptInvitation(Long badgeId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        BadgeMember member = badgeMemberRepository.findByBadgeIdAndUserId(badgeId, currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("No invitation found for this badge"));

        if (member.getStatus() != BadgeMemberStatus.PENDING) {
            throw new BusinessRuleException("NOT_PENDING", "No pending invitation found for this badge");
        }

        member.setStatus(BadgeMemberStatus.ACCEPTED);
        member.setJoinedAt(LocalDateTime.now());
        badgeMemberRepository.save(member);

        log.info("Badge {} invitation accepted by user {}", badgeId, currentUserId);

        return buildResponseFromDb(badge);
    }

    /**
     * Adds a new car plate to an existing badge slot on behalf of an accepted member.
     * Only the badge creator (canInvite=true) may call this.
     *
     * @param badgeId badge to add the car to
     * @param request plate number, optional car model, and the member's DB user ID
     * @return updated badge detail response
     */
    @Transactional
    public BadgeResponse addCar(Long badgeId, AddCarRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        // Verify caller is the badge creator
        BadgeMember callerMember = badgeMemberRepository.findByBadgeIdAndUserId(badgeId, currentUserId)
                .orElseThrow(() -> new BusinessRuleException("NOT_BADGE_CREATOR",
                        "You do not have permission to add cars to this badge"));
        if (!callerMember.getCanInvite()) {
            throw new BusinessRuleException("NOT_BADGE_CREATOR",
                    "You do not have permission to add cars to this badge");
        }

        // Enforce slot limit
        long carCount = badgeCarRepository.countByBadgeId(badgeId);
        if (carCount >= badge.getMaxSlots()) {
            throw new BusinessRuleException("NO_SLOTS_AVAILABLE", "All slots for this badge are filled");
        }

        // forUserId must be an ACCEPTED member
        badgeMemberRepository.findByBadgeIdAndUserIdAndStatus(badgeId, request.getForUserId(), BadgeMemberStatus.ACCEPTED)
                .orElseThrow(() -> new BusinessRuleException("NOT_A_MEMBER",
                        "The specified user is not an accepted member of this badge"));

        // Plate must not already be registered on this badge
        if (badgeCarRepository.existsByBadgeIdAndPlateNumber(badgeId, request.getPlateNumber())) {
            throw new BusinessRuleException("PLATE_ALREADY_REGISTERED",
                    "This plate is already registered under this badge");
        }

        User forUser = userRepository.findById(request.getForUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        BadgeCar badgeCar = BadgeCar.builder()
                .badge(badge)
                .user(forUser)
                .plateNumber(request.getPlateNumber())
                .carModel(request.getCarModel())
                .build();
        badgeCarRepository.save(badgeCar);

        log.info("Badge {} car {} added for user {}", badgeId, request.getPlateNumber(), request.getForUserId());

        return buildResponseFromDb(badge);
    }

    /**
     * Returns full badge detail to any current member (any BadgeMember status).
     *
     * @param badgeId badge to retrieve
     * @return badge detail response
     */
    public BadgeResponse getBadgeDetail(Long badgeId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        if (!badgeMemberRepository.existsByBadgeIdAndUserId(badgeId, currentUserId)) {
            throw new BusinessRuleException("NOT_A_MEMBER", "You are not a member of this badge");
        }

        return buildResponseFromDb(badge);
    }

    /**
     * Returns the most recent active or entered reservation for the given badge.
     * Caller must be an ACCEPTED member of the badge.
     *
     * @param badgeId badge whose reservation to retrieve
     * @return reservation summary response
     */
    public BadgeReservationResponse getBadgeReservation(Long badgeId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        badgeRepository.findById(badgeId)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        badgeMemberRepository.findByBadgeIdAndUserIdAndStatus(badgeId, currentUserId, BadgeMemberStatus.ACCEPTED)
                .orElseThrow(() -> new BusinessRuleException("NOT_A_MEMBER",
                        "You are not an accepted member of this badge"));

        Reservation reservation = reservationRepository
                .findFirstByBadgeIdAndStatusInOrderByReservedAtDesc(
                        badgeId, List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED))
                .orElseThrow(() -> new ResourceNotFoundException("No active reservation found for this badge"));

        return BadgeReservationResponse.builder()
                .reservationId(reservation.getId())
                .spotLabel(reservation.getSpot().getSpotLabel())
                .zoneCode(reservation.getSpot().getZone().getZoneCode())
                .status(reservation.getStatus().name())
                .reservedByName(reservation.getUser().getFullName())
                .reservedAt(reservation.getReservedAt())
                .expectedLeaveTime(reservation.getExpectedLeaveTime())
                .expiresAt(reservation.getExpiresAt())
                .build();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Semester 1 expires January 31, semester 2 expires June 30, both at 23:59:59.
     */
    private LocalDateTime calculateExpiresAt(int semesterNumber, int semesterYear) {
        if (semesterNumber == 1) {
            return LocalDateTime.of(semesterYear, 1, 31, 23, 59, 59);
        } else {
            return LocalDateTime.of(semesterYear, 6, 30, 23, 59, 59);
        }
    }

    /** Reloads members and cars from DB then delegates to buildResponse. */
    private BadgeResponse buildResponseFromDb(Badge badge) {
        List<BadgeMember> members = badgeMemberRepository.findByBadgeId(badge.getId());
        List<BadgeCar> cars = badgeCarRepository.findByBadgeId(badge.getId());
        return buildResponse(badge, members, cars);
    }

    private BadgeResponse buildResponse(Badge badge, List<BadgeMember> members, List<BadgeCar> cars) {
        List<BadgeResponse.MemberInfo> memberInfos = members.stream()
                .map(m -> BadgeResponse.MemberInfo.builder()
                        .userId(m.getUser().getId())
                        .name(m.getUser().getFullName())
                        .status(m.getStatus().name())
                        .canInvite(m.getCanInvite())
                        .build())
                .toList();

        List<BadgeResponse.CarInfo> carInfos = cars.stream()
                .map(c -> BadgeResponse.CarInfo.builder()
                        .plate(c.getPlateNumber())
                        .ownerName(c.getUser() != null ? c.getUser().getFullName() : null)
                        .build())
                .toList();

        return BadgeResponse.builder()
                .badgeId(badge.getId())
                .badgeType(badge.getBadgeType().name())
                .status(badge.getStatus().name())
                .pointsBalance(badge.getPointsBalance())
                .maxSlots(badge.getMaxSlots())
                .violationCount(badge.getViolationCount())
                .createdAt(badge.getCreatedAt())
                .expiresAt(badge.getExpiresAt())
                .members(memberInfos)
                .cars(carInfos)
                .build();
    }
}
