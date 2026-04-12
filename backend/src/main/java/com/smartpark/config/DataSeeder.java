// Seeds the database with initial zones, spots, admin account, and rewards on application startup.
// All seed operations are idempotent — existing records are skipped.
package com.smartpark.config;

import com.smartpark.model.Reward;
import com.smartpark.model.Spot;
import com.smartpark.model.User;
import com.smartpark.model.Zone;
import com.smartpark.model.enums.SpotStatus;
import com.smartpark.model.enums.UserRole;
import com.smartpark.model.enums.ZoneAccessType;
import com.smartpark.repository.RewardRepository;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.UserRepository;
import com.smartpark.repository.ZoneRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final ZoneRepository zoneRepository;
    private final SpotRepository spotRepository;
    private final UserRepository userRepository;
    private final RewardRepository rewardRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(ZoneRepository zoneRepository,
                      SpotRepository spotRepository,
                      UserRepository userRepository,
                      RewardRepository rewardRepository,
                      PasswordEncoder passwordEncoder) {
        this.zoneRepository = zoneRepository;
        this.spotRepository = spotRepository;
        this.userRepository = userRepository;
        this.rewardRepository = rewardRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        seedZones();
        seedSpots();
        seedAdmin();
        seedGuard();
        seedRewards();
    }

    private void seedZones() {
        seedZone("A", "Main Parking", ZoneAccessType.ALL);
        seedZone("B", "Carpool Zone", ZoneAccessType.CARPOOL_ONLY);
        seedZone("C", "Guest Area", ZoneAccessType.GUARD_ONLY);
    }

    private void seedZone(String code, String name, ZoneAccessType accessType) {
        if (zoneRepository.findByZoneCode(code).isPresent()) {
            log.info("Zone '{}' already exists — skipping", code);
            return;
        }
        zoneRepository.save(Zone.builder()
                .zoneCode(code)
                .zoneName(name)
                .accessType(accessType)
                .build());
        log.info("Seeded zone '{}'", code);
    }

    private void seedSpots() {
        Zone zoneA = zoneRepository.findByZoneCode("A").orElseThrow();
        Zone zoneB = zoneRepository.findByZoneCode("B").orElseThrow();
        Zone zoneC = zoneRepository.findByZoneCode("C").orElseThrow();

        List.of("A1", "A2", "A3", "A4", "A5").forEach(label -> seedSpot(label, zoneA));
        List.of("B1", "B2", "B3").forEach(label -> seedSpot(label, zoneB));
        List.of("C1", "C2").forEach(label -> seedSpot(label, zoneC));
    }

    private void seedSpot(String label, Zone zone) {
        if (spotRepository.findBySpotLabel(label).isPresent()) {
            log.info("Spot '{}' already exists — skipping", label);
            return;
        }
        spotRepository.save(Spot.builder()
                .zone(zone)
                .spotLabel(label)
                .status(SpotStatus.AVAILABLE)
                .statusUpdatedAt(LocalDateTime.now())
                .build());
        log.info("Seeded spot '{}'", label);
    }

    private void seedAdmin() {
        if (userRepository.findByEmail("admin@smartpark.com").isPresent()) {
            log.info("Admin account already exists — skipping");
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        userRepository.save(User.builder()
                .studentId(null)
                .fullName("Smart Park Admin")
                .email("admin@smartpark.com")
                .passwordHash(passwordEncoder.encode("Admin@2026"))
                .role(UserRole.ADMIN)
                .isActive(true)
                .createdAt(now)
                .updatedAt(now)
                .build());
        log.info("Seeded admin account 'admin@smartpark.com'");
    }

    private void seedGuard() {
        if (userRepository.findByEmail("guard@smartpark.com").isPresent()) {
            log.info("Guard account already exists — skipping");
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        userRepository.save(User.builder()
                .studentId("GUARD001")
                .fullName("Test Guard")
                .email("guard@smartpark.com")
                .passwordHash(passwordEncoder.encode("Guard@2026"))
                .role(UserRole.GUARD)
                .isActive(true)
                .createdAt(now)
                .updatedAt(now)
                .build());
        log.info("Seeded guard account 'guard@smartpark.com'");
    }

    private void seedRewards() {
        if (!rewardRepository.findAll().isEmpty()) {
            log.info("Rewards already exist — skipping");
            return;
        }
        rewardRepository.save(Reward.builder()
                .rewardName("Advance Reservation")
                .description("Reserve any spot from anywhere on campus without the geolocation requirement. Valid for one reservation.")
                .pointsCost(50)
                .rewardType("ADVANCE_RESERVATION")
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .build());
        log.info("Seeded reward 'Advance Reservation'");
    }
}