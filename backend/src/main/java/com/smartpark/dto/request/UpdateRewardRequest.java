// Request DTO for partially updating a reward's cost or active state.
package com.smartpark.dto.request;

import lombok.Data;

/**
 * All fields are optional — only non-null values are applied.
 */
@Data
public class UpdateRewardRequest {

    private Integer pointsCost;
    private Boolean isActive;
}