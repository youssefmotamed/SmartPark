// Repository for GuestParking entity — provides active session lookups by status and spot.
package com.smartpark.repository;

import com.smartpark.model.GuestParking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GuestParkingRepository extends JpaRepository<GuestParking, Long> {

    List<GuestParking> findByStatus(String status);

    Optional<GuestParking> findBySpotIdAndStatus(Long spotId, String status);
}