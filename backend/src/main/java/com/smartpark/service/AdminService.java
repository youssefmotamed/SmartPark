// Business logic for admin user management, badge management, analytics, violations, rewards, and spot control.
package com.smartpark.service;

import com.smartpark.dto.request.CreateUserRequest;
import com.smartpark.dto.request.SuspendBadgeRequest;
import com.smartpark.dto.request.UpdateBadgeRequest;
import com.smartpark.dto.request.UpdateRewardRequest;
import com.smartpark.dto.request.UpdateUserRequest;
import com.smartpark.dto.response.AdminBadgeResponse;
import com.smartpark.dto.response.AdminUserResponse;
import com.smartpark.dto.response.AdminViolationResponse;
import com.smartpark.dto.response.AnalyticsSummaryResponse;
import com.smartpark.dto.response.GuardReservationResponse;
import com.smartpark.dto.response.RewardResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.DuplicateResourceException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.Reward;
import com.smartpark.model.Spot;
import com.smartpark.model.User;
import com.smartpark.model.enums.*;
import com.smartpark.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for admin user management and badge management operations.
 */
@Service
public class AdminService {

    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private final UserRepository userRepository;
    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final ReservationRepository reservationRepository;
    private final ViolationRepository violationRepository;
    private final SpotRepository spotRepository;
    private final RewardRepository rewardRepository;
    private final GuestParkingRepository guestParkingRepository;
    private final PasswordEncoder passwordEncoder;

    public AdminService(UserRepository userRepository,
                        BadgeRepository badgeRepository,
                        BadgeMemberRepository badgeMemberRepository,
                        BadgeCarRepository badgeCarRepository,
                        ReservationRepository reservationRepository,
                        ViolationRepository violationRepository,
                        SpotRepository spotRepository,
                        RewardRepository rewardRepository,
                        GuestParkingRepository guestParkingRepository,
                        PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.badgeRepository = badgeRepository;
        this.badgeMemberRepository = badgeMemberRepository;
        this.badgeCarRepository = badgeCarRepository;
        this.reservationRepository = reservationRepository;
        this.violationRepository = violationRepository;
        this.spotRepository = spotRepository;
        this.rewardRepository = rewardRepository;
        this.guestParkingRepository = guestParkingRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Returns a filtered, paginated list of users.
     */
    public Page<AdminUserResponse> getUsers(int page, int size, String role, String search, Boolean isActive) {
        size = Math.min(size, 100);
        String roleParam = (role != null && !role.isBlank()) ? UserRole.valueOf(role).name() : null;
        String searchParam = (search != null && !search.isBlank()) ? search : null;
        return userRepository.findWithFilters(roleParam, isActive, searchParam, PageRequest.of(page, size))
                .map(AdminUserResponse::fromEntity);
    }

    /**
     * Creates a new user. For STUDENT role, also creates the initial badge, member, and car.
     */
    @Transactional
    public AdminUserResponse createUser(CreateUserRequest request) {
        UserRole role = UserRole.valueOf(request.getRole());

        if (role == UserRole.STUDENT) {
            if (request.getStudentId() == null || request.getStudentId().isBlank() ||
                    request.getPlateNumber() == null || request.getPlateNumber().isBlank()) {
                throw new BusinessRuleException("MISSING_FIELDS",
                        "studentId and plateNumber are required for STUDENT role");
            }
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("Email already registered");
        }

        if (role == UserRole.STUDENT && userRepository.existsByStudentId(request.getStudentId())) {
            throw new DuplicateResourceException("Student ID already registered");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .studentId(role == UserRole.STUDENT ? request.getStudentId() : null)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        user = userRepository.save(user);

        if (role == UserRole.STUDENT) {
            Badge badge = Badge.builder()
                    .badgeType(BadgeType.INDIVIDUAL)
                    .status(BadgeStatus.ACTIVE)
                    .createdByUser(user)
                    .maxSlots(1)
                    .pointsBalance(0)
                    .semesterNumber(1)
                    .semesterYear(2026)
                    .violationCount(0)
                    .createdAt(LocalDateTime.now())
                    .expiresAt(LocalDateTime.now().plusMonths(6))
                    .build();
            badge = badgeRepository.save(badge);

            BadgeMember member = BadgeMember.builder()
                    .badge(badge)
                    .user(user)
                    .status(BadgeMemberStatus.ACCEPTED)
                    .canInvite(true)
                    .joinedAt(LocalDateTime.now())
                    .createdAt(LocalDateTime.now())
                    .build();
            badgeMemberRepository.save(member);

            BadgeCar car = BadgeCar.builder()
                    .badge(badge)
                    .user(user)
                    .plateNumber(request.getPlateNumber())
                    .createdAt(LocalDateTime.now())
                    .build();
            badgeCarRepository.save(car);
        }

        log.info("Admin created user {} with role {}", user.getId(), role);
        return AdminUserResponse.fromEntity(user);
    }

    /**
     * Returns a single user by ID.
     */
    public AdminUserResponse getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return AdminUserResponse.fromEntity(user);
    }

    /**
     * Updates a user's full name and email.
     */
    @Transactional
    public AdminUserResponse updateUser(Long id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!user.getEmail().equals(request.getEmail()) &&
                userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("Email already registered");
        }

        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setUpdatedAt(LocalDateTime.now());
        user = userRepository.save(user);

        log.info("Admin updated user {}", id);
        return AdminUserResponse.fromEntity(user);
    }

    /**
     * Soft-deletes a user by setting isActive=false. Blocked if the user has active reservations
     * or accepted badge memberships.
     */
    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (reservationRepository.existsByUserIdAndStatusIn(id,
                List.of(ReservationStatus.ACTIVE, ReservationStatus.ENTERED))) {
            throw new BusinessRuleException("HAS_ACTIVE_RESERVATION",
                    "User has an active reservation and cannot be deleted");
        }

        if (badgeMemberRepository.existsByUserIdAndStatus(id, BadgeMemberStatus.ACCEPTED)) {
            throw new BusinessRuleException("HAS_BADGE_MEMBERSHIPS",
                    "User has active badge memberships and cannot be deleted");
        }

        user.setIsActive(false);
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        log.info("Admin deactivated user {}", id);
    }

    /**
     * Returns a filtered, paginated list of badges.
     */
    public Page<AdminBadgeResponse> getBadges(int page, int size, String status, String badgeType, String search) {
        size = Math.min(size, 100);
        String statusParam = (status != null && !status.isBlank()) ? BadgeStatus.valueOf(status).name() : null;
        String badgeTypeParam = (badgeType != null && !badgeType.isBlank()) ? BadgeType.valueOf(badgeType).name() : null;
        String searchParam = (search != null && !search.isBlank()) ? search : null;

        return badgeRepository.findWithFilters(statusParam, badgeTypeParam, searchParam, PageRequest.of(page, size))
                .map(badge -> {
                    List<BadgeMember> members = badgeMemberRepository.findByBadgeId(badge.getId());
                    return AdminBadgeResponse.fromEntity(badge, members);
                });
    }

    /**
     * Updates optional badge fields: badgeType (recalculates maxSlots), violationCount, expiresAt.
     */
    @Transactional
    public AdminBadgeResponse updateBadge(Long id, UpdateBadgeRequest request) {
        Badge badge = badgeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        if (request.getBadgeType() != null) {
            BadgeType newType = BadgeType.valueOf(request.getBadgeType());
            badge.setBadgeType(newType);
            badge.setMaxSlots(maxSlotsForType(newType));
        }
        if (request.getViolationCount() != null) {
            badge.setViolationCount(request.getViolationCount());
        }
        if (request.getExpiresAt() != null) {
            badge.setExpiresAt(request.getExpiresAt());
        }

        badge = badgeRepository.save(badge);
        log.info("Admin updated badge {}", id);

        List<BadgeMember> members = badgeMemberRepository.findByBadgeId(badge.getId());
        return AdminBadgeResponse.fromEntity(badge, members);
    }

    /**
     * Suspends a badge for the given number of days with a reason.
     */
    @Transactional
    public AdminBadgeResponse suspendBadge(Long id, SuspendBadgeRequest request) {
        Badge badge = badgeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        badge.setStatus(BadgeStatus.SUSPENDED);
        badge.setSuspendedUntil(LocalDateTime.now().plusDays(request.getSuspensionDays()));
        badge.setSuspensionReason(request.getReason());
        badge = badgeRepository.save(badge);

        log.warn("Admin suspended badge {} for {} days: {}", id, request.getSuspensionDays(), request.getReason());

        List<BadgeMember> members = badgeMemberRepository.findByBadgeId(badge.getId());
        return AdminBadgeResponse.fromEntity(badge, members);
    }

    /**
     * Lifts a suspension from a badge, restoring it to ACTIVE.
     */
    @Transactional
    public AdminBadgeResponse unsuspendBadge(Long id) {
        Badge badge = badgeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Badge not found"));

        badge.setStatus(BadgeStatus.ACTIVE);
        badge.setSuspendedUntil(null);
        badge.setSuspensionReason(null);
        badge = badgeRepository.save(badge);

        log.info("Admin unsuspended badge {}", id);

        List<BadgeMember> members = badgeMemberRepository.findByBadgeId(badge.getId());
        return AdminBadgeResponse.fromEntity(badge, members);
    }

    /**
     * Returns a real-time snapshot of parking lot occupancy, activity counts, and user totals.
     */
    public AnalyticsSummaryResponse getAnalyticsSummary() {
        long occupied = spotRepository.countByStatus(SpotStatus.OCCUPIED);
        long reserved = spotRepository.countByStatus(SpotStatus.RESERVED);
        long available = spotRepository.countByStatus(SpotStatus.AVAILABLE);
        long unavailable = spotRepository.countByStatus(SpotStatus.UNAVAILABLE);
        long total = occupied + reserved + available + unavailable;

        double occupancyRate = total == 0 ? 0.0
                : BigDecimal.valueOf((occupied + reserved) * 100.0 / total)
                        .setScale(2, RoundingMode.HALF_UP)
                        .doubleValue();

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        long reservationsToday = reservationRepository.countByReservedAtBetween(startOfDay, endOfDay);
        long violationsToday = violationRepository.countByCreatedAtBetween(startOfDay, endOfDay);

        long activeBadges = badgeRepository.countByStatus(BadgeStatus.ACTIVE);
        long suspendedBadges = badgeRepository.countByStatus(BadgeStatus.SUSPENDED);

        long totalStudents = userRepository.countByRole(UserRole.STUDENT);
        long totalGuards = userRepository.countByRole(UserRole.GUARD);

        return AnalyticsSummaryResponse.builder()
                .totalSpots(total)
                .occupiedSpots(occupied)
                .reservedSpots(reserved)
                .availableSpots(available)
                .unavailableSpots(unavailable)
                .occupancyRate(occupancyRate)
                .reservationsToday(reservationsToday)
                .violationsToday(violationsToday)
                .activeBadges(activeBadges)
                .suspendedBadges(suspendedBadges)
                .totalStudents(totalStudents)
                .totalGuards(totalGuards)
                .build();
    }

    /**
     * Returns a paginated list of all violations ordered by most recent first.
     */
    public Page<AdminViolationResponse> getViolations(int page, int size) {
        size = Math.min(size, 100);
        return violationRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size))
                .map(AdminViolationResponse::fromEntity);
    }

    /**
     * Updates a reward's pointsCost and/or isActive flag. Only non-null fields are applied.
     */
    @Transactional
    public RewardResponse updateReward(Long id, UpdateRewardRequest request) {
        Reward reward = rewardRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Reward not found"));

        if (request.getPointsCost() != null) {
            reward.setPointsCost(request.getPointsCost());
        }
        if (request.getIsActive() != null) {
            reward.setIsActive(request.getIsActive());
        }

        reward = rewardRepository.save(reward);
        return RewardResponse.fromEntity(reward, 0);
    }

    /**
     * Returns all currently active student reservations and active guest parking sessions,
     * using the same structure as the guard's active reservations view.
     */
    public List<GuardReservationResponse> getAdminActiveReservations() {
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

    /**
     * Directly sets a spot's status to the given value and records the timestamp.
     */
    @Transactional
    public void updateSpotStatus(Long spotId, String newStatus) {
        Spot spot = spotRepository.findById(spotId)
                .orElseThrow(() -> new ResourceNotFoundException("Spot not found"));

        SpotStatus status;
        try {
            status = SpotStatus.valueOf(newStatus);
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("INVALID_STATUS", "Invalid spot status");
        }

        spot.setStatus(status);
        spot.setStatusUpdatedAt(LocalDateTime.now());
        spotRepository.save(spot);

        log.info("Admin set spot {} status to {}", spot.getSpotLabel(), status);
    }

    private int maxSlotsForType(BadgeType type) {
        return switch (type) {
            case INDIVIDUAL -> 1;
            case CARPOOL_2 -> 2;
            case CARPOOL_3 -> 3;
            case CARPOOL_4 -> 4;
            case CARPOOL_5 -> 5;
        };
    }
}