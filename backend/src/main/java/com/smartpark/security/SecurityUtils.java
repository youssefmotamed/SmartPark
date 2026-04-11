// Utility methods for extracting the current authenticated user from the Spring Security context.
package com.smartpark.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

    private SecurityUtils() {}

    /**
     * Returns the ID of the currently authenticated user.
     */
    public static Long getCurrentUserId() {
        UserDetailsImpl userDetails = getPrincipal();
        return userDetails.getId();
    }

    /**
     * Returns the role name of the currently authenticated user.
     */
    public static String getCurrentUserRole() {
        UserDetailsImpl userDetails = getPrincipal();
        return userDetails.getRole().name();
    }

    private static UserDetailsImpl getPrincipal() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (UserDetailsImpl) auth.getPrincipal();
    }
}