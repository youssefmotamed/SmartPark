// Handles user registration, login, and token refresh for the SmartPark auth module.
package com.smartpark.service;

import com.smartpark.dto.request.LoginRequest;
import com.smartpark.dto.request.RefreshTokenRequest;
import com.smartpark.dto.request.RegisterRequest;
import com.smartpark.dto.response.AuthResponse;
import com.smartpark.dto.response.RegisterResponse;
import com.smartpark.exception.BusinessRuleException;
import com.smartpark.exception.DuplicateResourceException;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Badge;
import com.smartpark.model.BadgeCar;
import com.smartpark.model.BadgeMember;
import com.smartpark.model.User;
import com.smartpark.model.enums.BadgeMemberStatus;
import com.smartpark.model.enums.BadgeStatus;
import com.smartpark.model.enums.BadgeType;
import com.smartpark.model.enums.UserRole;
import com.smartpark.repository.BadgeCarRepository;
import com.smartpark.repository.BadgeMemberRepository;
import com.smartpark.repository.BadgeRepository;
import com.smartpark.repository.UserRepository;
import com.smartpark.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Service for user registration, login, and JWT token refresh.
 */
@Service
@Transactional
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final BadgeRepository badgeRepository;
    private final BadgeCarRepository badgeCarRepository;
    private final BadgeMemberRepository badgeMemberRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository,
                       BadgeRepository badgeRepository,
                       BadgeCarRepository badgeCarRepository,
                       BadgeMemberRepository badgeMemberRepository,
                       JwtTokenProvider jwtTokenProvider,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.badgeRepository = badgeRepository;
        this.badgeCarRepository = badgeCarRepository;
        this.badgeMemberRepository = badgeMemberRepository;
        this.jwtTokenProvider = jwtTokenProvider;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Registers a new student: creates the user, an INDIVIDUAL badge, a badge member entry,
     * and a badge car. Throws if the email or student ID is already taken.
     */
    public RegisterResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("Email already registered");
        }
        if (userRepository.existsByStudentId(request.getStudentId())) {
            throw new DuplicateResourceException("Student ID already registered");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .studentId(request.getStudentId())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.STUDENT)
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        user = userRepository.save(user);

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

        log.info("User {} registered successfully with badge {}", user.getId(), badge.getId());
        return new RegisterResponse(user.getId(), user.getStudentId(), user.getRole().name());
    }

    /**
     * Authenticates a user by email and password, then issues JWT access and refresh tokens.
     */
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new ResourceNotFoundException("Invalid email or password");
        }

        if (!user.getIsActive()) {
            throw new BusinessRuleException("ACCOUNT_DEACTIVATED", "Your account has been deactivated");
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        log.info("User {} logged in successfully", user.getId());
        return new AuthResponse(accessToken, refreshToken,
                new AuthResponse.UserInfo(user.getId(), user.getFullName(), user.getRole().name()));
    }

    /**
     * Validates a refresh token and issues a new access/refresh token pair.
     */
    public AuthResponse refresh(RefreshTokenRequest request) {
        if (!jwtTokenProvider.validateToken(request.getRefreshToken())) {
            throw new BusinessRuleException("INVALID_TOKEN", "Invalid or expired refresh token");
        }

        Long userId = jwtTokenProvider.getUserIdFromToken(request.getRefreshToken());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessRuleException("INVALID_TOKEN", "Invalid or expired refresh token"));

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        return new AuthResponse(accessToken, refreshToken,
                new AuthResponse.UserInfo(user.getId(), user.getFullName(), user.getRole().name()));
    }
}