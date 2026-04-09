// Repository for RewardRedemption entity — provides redemption history per user.
package com.smartpark.repository;

import com.smartpark.model.RewardRedemption;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RewardRedemptionRepository extends JpaRepository<RewardRedemption, Long> {

    List<RewardRedemption> findByUserIdOrderByRedeemedAtDesc(Long userId);
}