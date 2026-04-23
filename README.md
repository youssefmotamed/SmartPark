# Smart Park 🚗

A mobile parking management system for AAST Abu Qir branch, Alexandria. Smart Park allows university students to view real-time parking availability, reserve spots, and enter campus via QR code scanning at gates.

Built as a graduation project by Walid (frontend) and Youssef (backend).

---

## Features

- **Real-time parking map** — live spot availability updated every 30 seconds via camera detection
- **Spot reservation** — geolocation-gated reservations with 15-minute arrival window
- **QR code entry/exit** — guards scan QR codes at gates to validate entry and record exit
- **Points system** — students earn points for punctual departures, redeemable for rewards
- **Carpool badges** — groups of 2-5 students share one badge with one car on campus at a time
- **Guard dashboard** — guest parking, violation reporting, spot overrides
- **Admin dashboard** — user management, badge management, analytics, rewards configuration
- **Camera-based detection** — USB webcam with OpenCV frame difference detection

---

## Tech Stack

| Component | Technology |
|---|---|
| Mobile App | Flutter 3.x (Dart), Android |
| Backend API | Java 17, Spring Boot 3.x, Maven |
| Database | PostgreSQL 16 |
| ORM | Spring Data JPA / Hibernate |
| Authentication | Spring Security + JWT |
| Camera Processor | Python 3.11+, OpenCV, NumPy |

---

## Prerequisites

- Java 17+
- Maven (or use the included Maven wrapper `./mvnw`)
- PostgreSQL 16+
- Python 3.11+ (for camera processor)
- Flutter 3.x (for frontend)
- Android Studio or VS Code with Flutter extension

---

## Project Structure
smart-park/
├── frontend/          # Flutter/Dart mobile app (Walid)
├── backend/           # Spring Boot REST API (Youssef)
├── camera-processor/  # Python OpenCV spot detection (Youssef)
└── README.md

---

## Backend Setup

### 1. Clone the repository

```bash
git clone https://github.com/youssefmotamed/smart-park.git
cd smart-park
```

### 2. Create the database

Open pgAdmin or psql and create a new database:

```sql
CREATE DATABASE smartpark;
```

### 3. Configure application.properties

Create `backend/src/main/resources/application.properties`

```properties
# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/smartpark
spring.datasource.username=YOUR_DB_USERNAME
spring.datasource.password=YOUR_DB_PASSWORD

# JPA
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# JWT
jwt.secret=YOUR_JWT_SECRET_KEY
jwt.expiration=3600000
jwt.refresh-expiration=604800000

# Camera API Key
camera.api-key=YOUR_CAMERA_API_KEY

# Debug 
app.debug.skip-geolocation=false
```

### 4. Run the backend

```bash
cd backend
./mvnw spring-boot:run
```

The API will start on `http://localhost:8080`. On first run, the database tables are auto-created and seed data is inserted (3 zones, 10 spots, 1 admin account, 1 reward).

### 5. Default seed accounts

| Role | Email | Password |
|---|---|---|
| Admin | admin@smartpark.com | Admin@2026 |
| Guard | guard@smartpark.com | Guard@2026 |

Student accounts are created via the register API.

---

## Camera Processor Setup

### 1. Set up Python environment

```bash
cd camera-processor
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure environment variables

Create `camera-processor/.env`:
BACKEND_URL=http://localhost:8080/api/v1
CAMERA_API_KEY=YOUR_CAMERA_API_KEY
CAPTURE_INTERVAL=10

### 3. Calibrate spot regions

```bash
python calibrate.py
```

Follow the on-screen instructions to define the region of interest for each parking spot. Configuration is saved to `spots_config.json`.

### 4. Run the camera processor

```bash
python main.py
```

**Controls:**
- `r` — recapture reference frame
- `+` / `-` — adjust detection sensitivity
- `q` — quit

---

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

Make sure the backend is running and update the API base URL in `frontend/lib/config/constants.dart` to point to your machine's local IP address (not localhost) so the Android emulator or physical device can reach the backend.

---

## API Reference

Base URL: `http://localhost:8080/api/v1`

The backend exposes 51 REST endpoints across 12 modules:

| Module | Endpoints |
|---|---|
| Authentication | 3 |
| Student Profile | 2 |
| Spots & Zones | 3 |
| Reservations | 6 |
| Gate Scanning | 2 |
| Points | 3 |
| Rewards | 3 |
| Carpool & Badges | 6 |
| Notifications | 3 |
| Guard Dashboard | 5 |
| Admin Dashboard | 14 |
| Camera | 1 |

All endpoints return a standard JSON response:
```json
{ "success": true, "data": { ... }, "message": "..." }
```

Error responses:
```json
{ "success": false, "error": { "code": "ERROR_CODE", "message": "..." } }
```

---

## Parking Zones 

| Zone | Name | Access | Spots |
|---|---|---|---|
| A | Main Parking | All badges | A1-A5 |
| B | Carpool Zone | Carpool badges only | B1-B3 |
| C | Guest Area | Guard-managed | C1-C2 |

---

## Team

| Name | Role |
|---|---|
| Walid | Frontend — Flutter/Dart |
| Youssef | Backend — Java/Spring Boot + Camera Processor |

---

*AAST Abu Qir Branch — Alexandria, Egypt — Graduation Project 2026*