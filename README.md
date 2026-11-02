# Candela Mobile (Flutter)

The mobile client for **Candela**, an urban nightlife and social discovery platform built with **Flutter & Dart**. 

The application enables users to discover physical venues, coordinate plans with friends, verify physical attendance via GPS and photo check-ins, earn points, track streaks, and follow live activity feeds across Barranquilla and Bogotá.

---

## 📱 Features

- **🗺️ Geospatial Venue Discovery**: Interactive map displaying nearby venues, bars, and clubs with real-time distance calculations and venue details.
- **📸 GPS-Verified Check-Ins**: Two-phase check-in flow requiring physical GPS proximity and photo verification uploaded via presigned S3 URLs.
- **🔥 Live Activity Feed**: Chronological and algorithmic activity feed of friend check-ins, comments, and city highlights.
- **👥 Social Outing Plans**: Create public or friends-only plans, manage RSVPs, and coordinate meeting points.
- **🏆 Gamification & Streaks**: Weekly outing streaks, tier badges, point system, and regional leaderboards.
- **🔐 Secure Authentication**: JWT authentication with rotating sessions, Google OAuth flow with age-gate validation (18+ requirement).

---

## 🛠 Tech Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x (Dart 3.x)** | Cross-platform mobile architecture (iOS & Android). |
| **State Management** | **Provider / ValueNotifier** | Scoped reactive state with minimal boilerplate. |
| **Networking** | **HTTP & REST API** | Modular API client layer connecting to `candela-api`. |
| **Maps & Geo** | **Geolocator & Map SDK** | High-accuracy GPS positioning and geospatial pin rendering. |
| **Media & Storage** | **Camera & Image Picker** | In-app capture and presigned S3 upload management. |
| **Auth** | **Google Sign-In & JWT** | Secure token storage with automatic session refresh. |

---

## 📂 Architecture & Directory Structure

```text
lib/
├── app/                        # Feature screens and UI controllers
│   ├── map/                    # Map view, venue markers, and location sheet
│   ├── checkin_screen.dart     # Two-phase check-in UI and camera integration
│   ├── feed_screen.dart        # Real-time activity feed and photo viewer
│   ├── friends_screen.dart     # Friend management and friend requests
│   ├── plans_screen.dart       # Social plan coordination and RSVPs
│   ├── profile_screen.dart     # User profile, badges, and streak history
│   └── home_shell.dart         # Bottom navigation shell
├── auth/                       # Authentication flow
│   ├── login_screen.dart       # Standard email/password login
│   ├── join_screen.dart        # Account registration with age check
│   └── google_flow_button.dart # Google OAuth authentication
├── models/                     # Immutable data models and DTOs
│   ├── checkin.dart            # Check-in entity and upload state
│   ├── place.dart              # Venue and geospatial coordinate models
│   ├── plan.dart               # Outing plans and participant records
│   └── user.dart               # User profiles and gamification stats
├── providers/                  # Application state and theme providers
├── services/                   # Infrastructure and API client adapters
│   ├── api/                    # Domain-specific API services (Auth, Places, Feed, Plans)
│   ├── auth_service.dart       # Session token lifecycle manager
│   ├── google_signin_service.dart # Google SDK wrapper
│   └── location_service.dart   # GPS position provider and permission handler
├── config.dart                 # Application configuration and endpoints
├── main.dart                   # Application entry point
└── theme.dart                  # Typography, colors, and design tokens
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.12.1` or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- Android Studio / Xcode for mobile emulation or physical device debugging
- Running backend service ([candela-api](https://github.com/CubicMaldo/candela-api)) or staging endpoint

### Configuration

Copy the example environment configuration:

```bash
cp .env.json.example .env.json
```

Configure your local backend endpoint in `.env.json`:

```json
{
  "API_BASE_URL": "http://10.0.2.2:8080/api",
  "STORAGE_PUBLIC_ENDPOINT": "http://10.0.2.2:9000",
  "GOOGLE_SERVER_CLIENT_ID": "your-google-oauth-client-id"
}
```

*(Note: `10.0.2.2` is the Android emulator alias for your host's `localhost`).*

### Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run --dart-define-from-file=.env.json
   ```

3. Run the automated tests:
   ```bash
   flutter test
   ```

---

## 🗺️ Roadmap & Planned Work

Active frontend development roadmap (>20 hours of planned work):

- [ ] **Offline Caching & State Persistence**:
  - [ ] Implement local database storage (Hive / Isar) for offline feed reading and venue caching.
  - [ ] Optimistic UI updates with offline-first check-in queue that retries upon reconnecting.
- [ ] **Push Notifications & Real-Time Sync**:
  - [ ] Integrate Firebase Cloud Messaging (FCM) for background alerts (nearby friends, plan invites).
  - [ ] WebSocket / SSE consumer for live map presence and instant activity updates.
- [ ] **Media & UX Performance**:
  - [ ] Progressive blurhash image placeholders for fast feed scrolling.
  - [ ] Custom crop and compression pipeline before MinIO photo check-in uploads.
- [ ] **Automated Testing Suite**:
  - [ ] Golden UI tests for responsive device layouts (phones & tablets).
  - [ ] End-to-end integration tests using `flutter_test` covering auth and check-in flows.

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
