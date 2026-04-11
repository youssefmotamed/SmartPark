// Handles student profile and badge data retrieval.
package com.smartpark.service;

import com.smartpark.dto.response.BadgeDetailResponse;
import com.smartpark.dto.response.ProfileResponse;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.User;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.PointsLedgerRepository;
import com.smartpark.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service for retrieving a student's profile and associated badge details.
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class ProfileService {

    private static final Logger log = LoggerFactory.getLogger(ProfileService.class);

    private final UserRepository userRepository;
    private final BadgeRepository badgeRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final PointsLedgerRepository pointsLedgerRepository;

    /**
     * Returns the profile for the given user, including active badge summary and plate number.
     */
    public ProfileResponse getProfile(Long userId) {
        log.info("Fetching profile for user {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Find active badge created by this user
        Optional<Badge> activeBadgeOpt = badgeRepository.findByCreatedByUserId(userId).stream()
                .filter(b -> b.getStatus() == BadgeStatus.ACTIVE)
                .findFirst();

        ProfileResponse.ActiveBadgeInfo activeBadgeInfo = activeBadgeOpt.map(b ->
                ProfileResponse.ActiveBadgeInfo.builder()
                        .id(b.getId())
                        .type(b.getBadgeType().name())
                        .status(b.getStatus().name())
                        .build()
        ).orElse(null);

        int totalPoints = activeBadgeOpt.map(Badge::getPointsBalance).orElse(0);

        // Resolve plate number: first try the active badge's cars for this user
        String plateNumber = "N/A";
        if (activeBadgeOpt.isPresent()) {
            Optional<BadgeCar> car = badgeCarRepository.findByBadgeId(activeBadgeOpt.get().getId())
                    .stream()
                    .filter(c -> c.getUser() != null && c.getUser().getId().equals(userId))
                    .findFirst();
            if (car.isPresent()) {
                plateNumber = car.get().getPlateNumber();
            }
        }

        // Fallback: check all accepted badge memberships for a car linked to this user
        if ("N/A".equals(plateNumber)) {
            Optional<BadgeCar> fallbackCar = badgeMemberRepository.findByUserId(userId).stream()
                    .filter(m -> m.getStatus() == BadgeMemberStatus.ACCEPTED)
                    .flatMap(m -> badgeCarRepository.findByBadgeId(m.getBadge().getId()).stream())
                    .filter(c -> c.getUser() != null && c.getUser().getId().equals(userId))
                    .findFirst();
            if (fallbackCar.isPresent()) {
                plateNumber = fallbackCar.get().getPlateNumber();
            }
        }

        return ProfileResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .studentId(user.getStudentId())
                .email(user.getEmail())
                .plateNumber(plateNumber)
                .totalPoints(totalPoints)
                .activeBadge(activeBadgeInfo)
                .createdAt(user.getCreatedAt())
                .build();
    }

    /**
     * Returns full badge details for all badges the user is an accepted member of.
     */
    public List<BadgeDetailResponse> getProfileBadges(Long userId) {
        log.info("Fetching badges for user {}", userId);

        List<BadgeMember> memberships = badgeMemberRepository.findByUserId(userId).stream()
                .filter(m -> m.getStatus() == BadgeMemberStatus.ACCEPTED)
                .collect(Collectors.toList());

        return memberships.stream().map(membership -> {
            Badge badge = membership.getBadge();

            List<BadgeDetailResponse.MemberInfo> members = badgeMemberRepository.findByBadgeId(badge.getId())
                    .stream()
                    .map(m -> BadgeDetailResponse.MemberInfo.builder()
                            .userId(m.getUser().getId())
                            .name(m.getUser().getFullName())
                            .status(m.getStatus().name())
                            .build())
                    .collect(Collectors.toList());

            List<BadgeDetailResponse.CarInfo> cars = badgeCarRepository.findByBadgeId(badge.getId())
                    .stream()
                    .map(c -> BadgeDetailResponse.CarInfo.builder()
                            .plate(c.getPlateNumber())
                            .owner(c.getUser() != null ? c.getUser().getFullName() : "Unassigned")
                            .build())
                    .collect(Collectors.toList());

            return BadgeDetailResponse.builder()
                    .badgeId(badge.getId())
                    .badgeType(badge.getBadgeType().name())
                    .status(badge.getStatus().name())
                    .pointsBalance(badge.getPointsBalance())
                    .members(members)
                    .cars(cars)
                    .build();
        }).collect(Collectors.toList());
    }
}
