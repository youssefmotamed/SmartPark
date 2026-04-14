// Response returned by the camera spot-status endpoint summarising what was processed.
package com.smartpark.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Summary of the actions taken after processing a camera spot-status payload.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CameraUpdateResponse {

    /** Number of spots whose status was changed (RESERVED→OCCUPIED or OCCUPIED→AVAILABLE). */
    private int spotsUpdated;

    /** Number of spots that had a car with no matching reservation (contradiction events). */
    private int contradictionsDetected;

    /** Number of guard notifications created for contradiction events. */
    private int notificationsSent;
}