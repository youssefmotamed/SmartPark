// Defines the reason a guard manually overrides a parking spot's status.
package com.smartpark.model.enums;

public enum OverrideReason {
    CAMERA_ERROR,
    LEFT_UNDETECTED,
    MAINTENANCE,
    EVENT,
    OTHER
}
