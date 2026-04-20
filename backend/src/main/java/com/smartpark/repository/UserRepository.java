// Repository for User entity — provides lookup by email and studentId.
package com.smartpark.repository;

import com.smartpark.model.User;
import com.smartpark.model.enums.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByStudentId(String studentId);

    boolean existsByEmail(String email);

    boolean existsByStudentId(String studentId);

    List<User> findByRole(UserRole role);

    @Query(value = "SELECT * FROM users u WHERE " +
           "(:role IS NULL OR u.role = :role) AND " +
           "(:isActive IS NULL OR u.is_active = :isActive) AND " +
           "(:search IS NULL OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(COALESCE(u.student_id, '')) LIKE LOWER(CONCAT('%', :search, '%')))",
           countQuery = "SELECT COUNT(*) FROM users u WHERE " +
           "(:role IS NULL OR u.role = :role) AND " +
           "(:isActive IS NULL OR u.is_active = :isActive) AND " +
           "(:search IS NULL OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(COALESCE(u.student_id, '')) LIKE LOWER(CONCAT('%', :search, '%')))",
           nativeQuery = true)
    Page<User> findWithFilters(@Param("role") String role,
                               @Param("isActive") Boolean isActive,
                               @Param("search") String search,
                               Pageable pageable);
}