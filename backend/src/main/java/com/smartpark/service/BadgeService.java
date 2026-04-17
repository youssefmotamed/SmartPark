// Business logic for badge creation and management.
package com.smartpark.service;

import com.smartpark.dto.request.CreateBadgeRequest;
import com.smartpark.dto.response.BadgeResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.User;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.BadgeType;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
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
