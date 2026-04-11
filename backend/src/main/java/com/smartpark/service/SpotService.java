// Handles spot and zone data retrieval for the parking map.
package com.smartpark.service;

import com.smartpark.dto.response.SpotResponse;
import com.smartpark.dto.response.ZoneResponse;
import com.smartpark.exception.ResourceNotFoundException;
import com.smartpark.model.Spot;
import com.smartpark.model.Zone;
import com.smartpark.repository.SpotRepository;
import com.smartpark.repository.ZoneRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SpotService {

    private final SpotRepository spotRepository;
    private final ZoneRepository zoneRepository;

    private static final Logger log = LoggerFactory.getLogger(SpotService.class);

    /**
     * Returns all parking zones.
     */
    public List<ZoneResponse> getAllZones() {
        log.info("Fetching all zones");
        return zoneRepository.findAll().stream()
                .map(this::toZoneResponse)
                .collect(Collectors.toList());
    }

    /**
     * Returns all spots, or only spots belonging to the given zone if zoneCode is provided.
     * Throws ResourceNotFoundException if zoneCode is provided but not found.
     */
    public List<SpotResponse> getAllSpots(String zoneCode) {
        log.info("Fetching spots with zoneCode={}", zoneCode);
        if (zoneCode == null) {
            return spotRepository.findAll().stream()
                    .map(this::toSpotResponse)
                    .collect(Collectors.toList());
        }
        Zone zone = zoneRepository.findByZoneCode(zoneCode)
                .orElseThrow(() -> new ResourceNotFoundException("Zone not found: " + zoneCode));
        return spotRepository.findByZoneId(zone.getId()).stream()
                .map(this::toSpotResponse)
                .collect(Collectors.toList());
    }

    /**
     * Returns a single spot by ID.
     * Throws ResourceNotFoundException if the spot does not exist.
     */
    public SpotResponse getSpotById(Long spotId) {
        log.info("Fetching spot with id={}", spotId);
        Spot spot = spotRepository.findById(spotId)
                .orElseThrow(() -> new ResourceNotFoundException("Spot not found"));
        return toSpotResponse(spot);
    }

    private ZoneResponse toZoneResponse(Zone zone) {
        return new ZoneResponse(
                zone.getId(),
                zone.getZoneCode(),
                zone.getZoneName(),
                zone.getAccessType().name()
        );
    }

    private SpotResponse toSpotResponse(Spot spot) {
        return new SpotResponse(
                spot.getId(),
                spot.getSpotLabel(),
                spot.getZone().getZoneCode(),
                spot.getZone().getZoneName(),
                spot.getStatus().name(),
                spot.getStatusUpdatedAt()
        );
    }
}
