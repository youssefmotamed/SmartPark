// Repository for Reward entity — provides listing of active redeemable rewards.
package com.smartpark.repository;

import com.smartpark.model.Reward;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RewardRepository extends JpaRepository<Reward, Long> {

    List<Reward> findByIsActiveTrue();
}