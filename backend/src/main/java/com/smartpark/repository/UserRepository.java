// Repository for User entity — provides lookup by email and studentId.
package com.smartpark.repository;

import com.smartpark.model.User;
import com.smartpark.model.enums.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByStudentId(String studentId);

    boolean existsByEmail(String email);

    boolean existsByStudentId(String studentId);

    List<User> findByRole(UserRole role);
}