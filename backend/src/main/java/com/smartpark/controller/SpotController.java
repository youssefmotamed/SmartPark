// REST controller for zones and spots endpoints.
package com.smartpark.controller;

import com.smartpark.dto.response.ApiResponse;
import com.smartpark.dto.response.SpotResponse;
import com.smartpark.dto.response.ZoneResponse;
import com.smartpark.service.SpotService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class SpotController {

    private final SpotService spotService;

    /**
     * Returns all parking zones.
     * GET /api/v1/zones
     */
    @GetMapping("/zones")
    public ResponseEntity<ApiResponse<List<ZoneResponse>>> getAllZones() {
        List<ZoneResponse> zones = spotService.getAllZones();
        return ResponseEntity.ok(ApiResponse.success(zones));
    }

    /**
     * Returns all spots, optionally filtered by zone code.
     * GET /api/v1/spots?zoneCode=A
     */
    @GetMapping("/spots")
    public ResponseEntity<ApiResponse<List<SpotResponse>>> getAllSpots(
            @RequestParam(required = false) String zoneCode) {
        List<SpotResponse> spots = spotService.getAllSpots(zoneCode);
        return ResponseEntity.ok(ApiResponse.success(spots));
    }

    /**
     * Returns a single spot by ID.
     * GET /api/v1/spots/{spotId}
     */
    @GetMapping("/spots/{spotId}")
    public ResponseEntity<ApiResponse<SpotResponse>> getSpotById(@PathVariable Long spotId) {
        SpotResponse spot = spotService.getSpotById(spotId);
        return ResponseEntity.ok(ApiResponse.success(spot));
    }
}