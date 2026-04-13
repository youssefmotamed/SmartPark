// Enables Spring's @Scheduled task execution across the application.
package com.smartpark.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Activates Spring's scheduled task infrastructure so that @Scheduled methods
 * in service beans (e.g. ReservationExpiryService) are executed automatically.
 */
@Configuration
@EnableScheduling
public class SchedulerConfig {
}