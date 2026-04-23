# Smart Park — Technical Documentation

**Version:** 1.0 | **Date:** April 2026
**Project:** Graduation Project — AAST Abu Qir Branch, Alexandria, Egypt
**Team:** Walid (Frontend) & Youssef (Backend)

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture](#2-architecture)
3. [Database Design](#3-database-design)
4. [Backend Modules](#4-backend-modules)
5. [Key Business Logic](#5-key-business-logic)
6. [Security Architecture](#6-security-architecture)
7. [Scheduled Jobs](#7-scheduled-jobs)
8. [Camera Processor](#8-camera-processor)
9. [API Design Principles](#9-api-design-principles)
10. [Key Design Decisions](#10-key-design-decisions)

---

## 1. System Overview

Smart Park is a mobile parking management system designed to solve university parking congestion. The system gives students real-time visibility into parking availability, allows them to reserve spots before arriving, and uses QR codes at the gate for entry and exit validation.

The platform introduces two core innovations:

- **Points-based incentives** — students earn points for leaving their spots on time, encouraging higher turnover and reducing congestion.
- **Carpool subscriptions** — groups of 2-5 students share a single parking badge, allowing only one car on campus at a time. This reduces the total number of cars while splitting the cost among members.

The system has three user roles: **STUDENT** (reserves spots, earns points, manages badges), **GUARD** (scans QR codes at gates, manages guest parking, reports violations), and **ADMIN** (manages users, badges, spots, and views analytics).

---

## 2. Architecture

The system consists of three independently running components:

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                    │
│         (Student, Guard, and Admin interfaces)           │
│              Polls backend every 30 seconds              │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP / JWT
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Spring Boot REST API (Port 8080)            │
│         Business logic, auth, reservations, points       │
│                  PostgreSQL via JPA/Hibernate             │
└──────────┬──────────────────────────────────────────────┘
           │                          ▲
           │ JPA                      │ POST /camera/spot-status
           ▼                          │ (every 10 seconds, X-API-Key)
┌──────────────────┐       ┌──────────────────────────────┐
│   PostgreSQL 16   │       │   Python Camera Processor    │
│   (14 tables)     │       │   OpenCV frame difference    │
└──────────────────┘       └──────────────────────────────┘
```

**Data flow summary:**
1. The camera processor captures frames every 10 seconds, compares each spot's region of interest against a reference frame, and sends a batch status update to the backend.
2. The backend updates spot statuses, checks for contradictions (occupied spot with no reservation), and creates guard notifications if needed.
3. The Flutter app polls the backend every 30 seconds for updated spot data and notifications.
4. When a student reserves, the backend validates all rules, sets the spot to RESERVED, and returns a QR code.
5. Guards scan QR codes at entry and exit gates. Entry is validated, exit triggers points calculation.

---

## 3. Database Design

The database has 14 tables organized around the core entities of the system.

### 3.1 Table Summary

| Table | Purpose |
|---|---|
| `users` | All application users (students, guards, admins) |
| `badges` | Parking subscriptions (individual or carpool) |
| `badge_members` | Maps users to badges with invite status |
| `badge_cars` | Cars registered under each badge (one per slot) |
| `zones` | Parking zones with access rules (A, B, C) |
| `spots` | Individual parking spaces within zones |
| `reservations` | Active and historical parking reservations |
| `violations` | Violation reports filed by guards |
| `points_ledger` | Immutable ledger of all points transactions |
| `notifications` | In-app notification records for all users |
| `guest_parking` | Guest/visitor parking managed by guards |
| `spot_overrides` | Audit log of manual spot status changes by guards |
| `rewards` | Available rewards in the points store |
| `reward_redemptions` | Records of reward purchases by users |

### 3.2 Key Relationships

- A **User** can belong to multiple **Badges** through **BadgeMember** records.
- A **Badge** has one or more **BadgeCar** records (one per slot, up to `max_slots`).
- A **Reservation** belongs to one **Badge** and one **Spot**. Points earned are stored on the reservation after exit scan.
- **PointsLedger** entries are immutable — points are never edited or deleted. Spending and expiry are represented as negative entries. The badge's `points_balance` is kept in sync as a denormalized field for performance.
- **Notifications** are never deleted, only marked as read.

### 3.3 Parking Zones (MVP)

| Zone | Name | Access Type | Spots |
|---|---|---|---|
| A | Main Parking | ALL (individual + carpool) | A1–A5 |
| B | Carpool Zone | CARPOOL_ONLY | B1–B3 |
| C | Guest Area | GUARD_ONLY | C1–C2 |

Zone B is restricted to carpool badges only, incentivizing the carpool subscription model. Zone C is exclusively for guard-managed guest parking and cannot be reserved by students.

---

## 4. Backend Modules

The backend is organized into 12 modules. Each module contains an entity, repository, service, controller, and DTOs.

### M1 — Auth & Users
Handles registration, login, and JWT token refresh. Registration auto-creates an INDIVIDUAL badge, a BadgeMember record, and a BadgeCar record for the student's plate. Guards and admin accounts are created only by admins.

### M2 — Spots & Zones
Read-only endpoints that return all zones and spots with their current status. This is the primary data source for the student's parking map. Spots are polled by the Flutter app every 30 seconds.

### M3 — Profile
Returns the authenticated student's profile and all badges they belong to, including member lists and registered cars.

### M4 — Reservations
The core module. Handles reservation creation (with 8 ordered validation checks), reservation history, active reservation retrieval, QR code retrieval, and cancellation. Also contains the advance reservation endpoint which skips the geolocation check.

### M5 — Gate Scanning
Two endpoints for guards: entry scan (validates the QR code and records entry) and exit scan (closes the reservation and triggers points calculation).

### M6 — Daily Reset
No API endpoint. A scheduled job that runs at 8:00 PM daily to clear all active/entered reservations, reset spots to AVAILABLE, and close active guest parking sessions.

### M7 — Camera
A single endpoint authenticated via API key (not JWT). Receives batch spot status updates from the Python camera processor every 10 seconds, applies the departure buffer logic, and triggers contradiction detection.

### M8 — Notifications
Central notification system. All other modules call the `NotificationService` to create notifications. Students and guards poll `GET /notifications` every 30 seconds. Supports mark-as-read for individual and all notifications.

### M9 — Points
Three read-only endpoints: balance (current points and multiplier), history (paginated ledger), and summary (total earned, spent, expiring soon). Points are calculated and written by the Gate module on exit scan.

### M10 — Rewards
Students can view available rewards, redeem points for rewards, and view their redemption history. The only MVP reward is the Advance Reservation token, which allows one reservation without the geolocation check.

### M11 — Carpool & Badges
Handles badge creation (individual or carpool), member invitations, invitation acceptance, extra car registration, and badge detail retrieval. Enforces the one-car-at-a-time rule across all reservation creation.

### M12 — Guard & Admin
Guard endpoints: active reservations list, guest parking management, violation reporting, and spot overrides with audit log. Admin endpoints: full user CRUD, badge management (suspend/unsuspend/edit), analytics summary, violations list, active reservations, spot status control, and rewards configuration.

---

## 5. Key Business Logic

### 5.1 Reservation Validation Chain

When a student creates a reservation, the backend runs 8 ordered validations before accepting:

1. **Badge ownership** — the badge belongs to the requesting user
2. **Badge active** — badge is not suspended or expired
3. **One reservation per badge** — no ACTIVE or ENTERED reservation already exists for this badge (covers both individual and carpool)
4. **Spot availability** — the spot status is AVAILABLE
5. **Zone access** — the badge type matches the zone's access type (e.g., INDIVIDUAL badge cannot reserve Zone B)
6. **Geolocation gate** — the student's coordinates are within approximately 5km of campus (Haversine formula). Bypassed for advance reservations and skippable via a debug flag for development.
7. **Same-spot restriction** — the student's most recent expired or cancelled reservation is not for the same spot
8. **Expiry calculation** — sets `expires_at` to 15 minutes from now

If all validations pass, the spot is set to RESERVED and a QR code is generated containing only the reservation ID.

### 5.2 Geolocation Gate

The geolocation check uses the Haversine formula to calculate the great-circle distance between the student's reported coordinates and the campus coordinates (AAST Abu Qir: lat=31.2156, lng=29.9553). If the distance exceeds 5km, the reservation is rejected with a `TOO_FAR` error.

This gate is designed to prevent students from reserving spots while they are still at home. It can be bypassed by spending points on an Advance Reservation reward, or disabled via the `app.debug.skip-geolocation=true` configuration flag during development.

### 5.3 QR Code Entry/Exit Flow

The same QR code is used for both entry and exit. The QR data is a unique string generated at reservation creation time (format: `SP-RES-{UUID}`). At entry, the guard's app sends the QR string to `POST /gate/scan-entry`. The backend validates the reservation is ACTIVE and not expired, sets it to ENTERED, nullifies `expires_at` (the reservation now never expires), and returns the student's name, badge type, and registered plate numbers for the guard to verify physically.

At exit, the guard sends the same QR string to `POST /gate/scan-exit`. The backend sets the reservation to COMPLETED, triggers points calculation, and returns the points earned.

### 5.4 Post-Entry Persistence

After the entry scan, the 15-minute timer displayed on the student's screen is for motivation only — the reservation cannot expire after entry. The student is committed to the campus visit and must scan exit to close the reservation. This prevents a student from losing their reservation while searching for their spot.

### 5.5 Points Calculation

Points are calculated at exit scan based on how closely the student's actual departure matched their stated expected leaving time:

| Departure Timing | Points |
|---|---|
| 0–5 minutes before stated time | 10 |
| 6–15 minutes before | 8 |
| 16–30 minutes before | 5 |
| More than 30 minutes before | 0 |
| 1–10 minutes late | 8 |
| 11–20 minutes late | 5 |
| 21–30 minutes late | 3 |
| 31–60 minutes late | 1 |
| More than 60 minutes late | 0 |

The base points are then multiplied by the badge's carpool multiplier:

| Badge Type | Multiplier |
|---|---|
| INDIVIDUAL | 1.0× |
| CARPOOL_2 | 1.2× |
| CARPOOL_3 | 1.4× |
| CARPOOL_4 | 1.6× |
| CARPOOL_5 | 1.8× |

Carpool badges earn bonus points to incentivize the carpool model. Points belong to the badge (not individual members) and accumulate in the `points_ledger`. Points expire approximately 365 days after they are earned.

### 5.6 Carpool One-Car-at-a-Time Rule

A carpool badge can have 2–5 registered cars across its slots. However, only one car can be on campus at a time. This is enforced at the reservation creation level: if any reservation with status ACTIVE or ENTERED already exists for a badge, no new reservation can be created using that badge. This single check covers both individual badges (preventing double booking) and carpool badges (enforcing the carpool rule).

### 5.7 Violation Suspension Scaling

When a guard reports a violation by plate number, the backend looks up the badge associated with that plate and applies a suspension based on the badge's current violation count:

| Violation Number | Suspension Duration |
|---|---|
| 1st violation | 1 day |
| 2nd violation | 3 days |
| 3rd violation | 7 days |
| 4th and beyond | 7 days |

The violation count is stored on the badge and resets when a new badge is created for a new semester. Suspension prevents reservation creation but does not prevent gate entry (a suspended student who already has a QR code can still exit campus).

When a violation is reported, if the badge has an active reservation, it is automatically cancelled and the spot is freed.

### 5.8 Camera Contradiction Detection

When the camera reports a spot as OCCUPIED but no ACTIVE or ENTERED reservation exists for that spot (and no active guest parking), the system creates a `SPOT_CONTRADICTION` notification for all guards. This alerts the guard to investigate a potentially unauthorized vehicle.

Zone C (guest area) is excluded from contradiction detection since guest parking does not go through the reservation system.

### 5.9 Departure Buffer

When the camera reports a spot as empty, it does not immediately set the spot to AVAILABLE. Instead, the backend uses a departure buffer: the spot is only set to AVAILABLE after 6 consecutive empty readings (60 seconds). This prevents false AVAILABLE states caused by a car temporarily moving within a spot or camera noise. The buffer count is maintained in memory (ConcurrentHashMap) and resets on server restart.

---

## 6. Security Architecture

### 6.1 Authentication

All API endpoints except registration, login, and token refresh require a valid JWT Bearer token in the `Authorization` header. The JWT contains the user's ID, role, and expiration time. Access tokens expire after 1 hour; refresh tokens expire after 7 days.

### 6.2 Role-Based Access Control

Three roles are enforced at the endpoint level:

- **STUDENT** — reservation, points, rewards, badge, notification endpoints
- **GUARD** — gate scanning, guard dashboard endpoints, notification endpoints
- **ADMIN** — all admin dashboard endpoints

Role enforcement uses Spring Security's `@PreAuthorize("hasRole('ROLE')")` annotations at the controller level. A STUDENT token cannot call GUARD or ADMIN endpoints and receives a 403 response.

### 6.3 Camera Authentication

The camera processor does not use JWT. It authenticates via a static API key sent in the `X-API-Key` header. This key is configured in `application.properties` and matched in `CameraController`. This design keeps the camera integration simple since the processor runs on the same local machine as the backend.

### 6.4 Current User Extraction

Services never trust a `user_id` from the request body. The current user's ID is always extracted from the JWT token via `SecurityUtils.getCurrentUserId()`, which reads from `SecurityContextHolder`. This prevents a student from impersonating another user by passing a different ID in their request.

### 6.5 Password Security

All passwords are hashed using BCrypt via Spring Security's `PasswordEncoder`. Plaintext passwords are never stored or logged.

---

## 7. Scheduled Jobs

Three scheduled jobs run automatically in the background:

### 7.1 Reservation Expiry Check
**Schedule:** Every 60 seconds
**Purpose:** Finds all ACTIVE reservations where `expires_at` is in the past and sets them to EXPIRED. Frees the associated spot back to AVAILABLE. Creates a `RESERVATION_EXPIRED` notification for the student.

### 7.2 Five-Minute Warning
**Schedule:** Every 60 seconds
**Purpose:** Finds all ACTIVE reservations where `expires_at` is within the next 5 minutes and a warning has not yet been sent. Creates a `FIVE_MIN_WARNING` notification for all accepted badge members.

### 7.3 Daily Reset
**Schedule:** Every day at 8:00 PM (cron: `0 0 20 * * *`)
**Purpose:** Clears all stale data at the end of the day. Sets all ACTIVE reservations to EXPIRED, all ENTERED reservations to COMPLETED, resets all RESERVED or OCCUPIED spots to AVAILABLE, and closes all active guest parking sessions. This ensures no reservations carry over to the next day and the campus starts fresh each morning.

---

## 8. Camera Processor

The Python camera processor runs independently on the same machine as the backend. It uses OpenCV to detect parking spot occupancy through frame difference analysis.

### 8.1 Detection Approach

On startup, the processor captures a reference frame representing the empty parking lot. Every 10 seconds, it captures a new frame and compares each spot's region of interest (ROI) against the corresponding region in the reference frame. If the pixel difference exceeds a configurable threshold, the spot is classified as occupied.

### 8.2 Calibration

The ROI coordinates for each of the 10 spots are defined using the `calibrate.py` tool, which allows the user to draw bounding boxes over each spot on a live camera feed. The coordinates are saved to `spots_config.json` and loaded by `main.py` on startup.

### 8.3 Communication

Every 10 seconds, the processor sends a batch POST request to `/api/v1/camera/spot-status` containing the occupancy status of all 10 spots. The backend processes this batch atomically, applying the departure buffer and contradiction detection logic.

### 8.4 Controls

While running, the processor supports keyboard controls: `r` to recapture the reference frame (useful if lighting conditions change), `+`/`-` to adjust detection sensitivity, and `q` to quit.

---

## 9. API Design Principles

### 9.1 Standard Response Format

All endpoints return a consistent JSON envelope:

```json
{ "success": true, "data": { ... }, "message": "Operation successful" }
```

Errors always return:
```json
{ "success": false, "error": { "code": "ERROR_CODE", "message": "Human-readable description" } }
```

### 9.2 HTTP Status Codes

| Code | When Used |
|---|---|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST that creates a resource |
| 400 | Validation error (missing or invalid fields) |
| 401 | Missing or invalid JWT token |
| 403 | Valid token but insufficient role |
| 404 | Resource not found |
| 409 | Duplicate resource (e.g., email already registered) |
| 422 | Business rule violation (e.g., badge suspended, spot not available) |

### 9.3 Pagination

All list endpoints that can return large datasets use Spring Data's `Pageable` for pagination. Default page size is 20, maximum is 100. Responses include `totalElements`, `totalPages`, `number`, and `size` alongside the `content` array.

### 9.4 Field Naming

Request and response fields use camelCase (e.g., `badgeType`, `spotLabel`, `expectedLeaveTime`). Database columns use snake_case (e.g., `badge_type`, `spot_label`, `expected_leave_time`). The mapping between the two is handled by Spring Data JPA and Jackson.

---

## 10. Key Design Decisions

### 10.1 Why Polling Instead of Push Notifications

The system uses polling (the app calls the backend every 30 seconds) instead of WebSockets or push notifications. This was a deliberate choice for the MVP to avoid the complexity of maintaining persistent connections or integrating with FCM/APNs. For a university campus with predictable usage patterns, 30-second polling provides acceptable real-time feel without requiring infrastructure changes.

### 10.2 Why Points Belong to the Badge, Not the User

Points are accumulated on the badge rather than on individual users. This is because the carpool model requires shared ownership — when a carpool group earns points for an on-time departure, all members contributed equally. At semester end, the badge's points are divided equally among all accepted members. Individual badges work the same way for consistency.

### 10.3 Why the QR Code Contains Only the Reservation ID

The QR code data is a short unique string (e.g., `SP-RES-8BCFA123`) that maps to a reservation in the database. It contains no user data, no spot data, and no timestamps. All validation happens server-side when the guard scans. This makes the QR code safe to display on screen without exposing any sensitive information, and means the same QR works for both entry and exit without regeneration.

### 10.4 Why the Same-Spot Restriction Exists

After a reservation expires or is cancelled, the student cannot immediately re-reserve the same spot. This prevents a student from holding a spot indefinitely by creating and cancelling reservations in a loop. They must choose a different spot for their next reservation.

### 10.5 Why the Departure Buffer Is 6 Readings

The 60-second departure buffer (6 consecutive empty readings at 10-second intervals) balances responsiveness with accuracy. A shorter buffer would cause false AVAILABLE states from cars temporarily shifting. A longer buffer would delay spot availability unnecessarily. Six readings was chosen as a practical middle ground for the tabletop model using toy cars.

### 10.6 Why Soft Delete for Users

Users are never hard-deleted from the database. Setting `is_active=false` preserves referential integrity — all their historical reservations, violation records, and points ledger entries remain linked to their account. This is important for audit trails and for the integrity of the analytics dashboard.

---

*Smart Park — AAST Abu Qir Branch — Graduation Project 2026*
