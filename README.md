# FieldGuard — Field Agent App

**FieldGuard** is the field-agent (employee) mobile app for a sales & collections field-force platform. Agents log in, follow an assigned route with live turn-by-turn navigation, automatically check in to shops via geofencing, work through per-task checklists, record cash/cheque collections (with an SMS receipt to the shopkeeper), and stay in sync through realtime + push notifications.

> Built with Flutter. This repository is the **employee** app (`com.example.field_guard_re`). The manager/admin app (`com.agnibits.field_guard`) is a separate codebase that shares the same backend and Firebase project.

---

## Screenshots

| Today's Route | Geofenced Check‑in | Task Detail |
| :---: | :---: | :---: |
| ![Today's Route](screenshots/Employee%20route%20Screen.png) | ![Geofenced check-in](screenshots/Geofenced%20check-in.png) | ![Task Detail](screenshots/Employee%20TaskDetail%20Screen.png) |
| Live tracking + Mapbox navigation to the next stop | Auto check‑in when the agent enters a shop's geofence | Per‑item checklist, timeline, shop & location context |

---

## Features

- **Authentication** — phone + password login, JWT access/refresh tokens stored in secure storage, automatic silent refresh on resume.
- **Home dashboard** — consolidated summary (profile, one task per status, live‑tracking state) fetched in a single round‑trip.
- **Route & navigation** — today's schedule with live location tracking and Mapbox turn‑by‑turn directions to the next stop.
- **Geofenced check‑in** — background location service detects shop enter/exit and records a geofence visit; the backend completes the in‑progress task and the app refreshes. Survives app swipe‑kills.
- **Tasks** — task list, detail with per‑item checklist + progress, timeline (due/created/updated), and full task history.
- **Shops** — browse shops, view API‑backed shop details, and create a new shop via a *stand‑at‑shop* map flow that captures GPS coordinates.
- **Collections** — record a cash/cheque collection against a shop's outstanding ledger; the backend authors an SMS receipt that's shown and confirmed in‑app.
- **Notifications** — in‑app inbox (unread counts, mark‑read), FCM push, and a realtime socket for live updates while foregrounded.
- **Profile** — view/edit personal details and current‑month stats.
- **Legal** — terms & privacy screens, accessible before login.

---

## Tech Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK `^3.11.5`) |
| State management | `flutter_riverpod` |
| Routing | `go_router` |
| Networking | `dio` (with auth / error / logging interceptors) |
| Maps & navigation | `mapbox_maps_flutter` + Mapbox Directions |
| Location | `geolocator`, `flutter_background_service`, `permission_handler` |
| Push & realtime | `firebase_messaging`, `socket_io_client`, `flutter_local_notifications` |
| Storage | `flutter_secure_storage` |
| Serialization | `json_serializable` / `json_annotation` (build_runner) |
| Config | `flutter_dotenv` |

---

## Project Structure

The codebase is organized **feature‑first** with a shared `core/` layer. Most features follow a clean‑architecture split of `data / domain / presentation`.

```
lib/
├── main.dart                  # Bootstraps dotenv, Mapbox, notifications, Firebase/FCM,
│                              # background location, and visit recovery
├── core/
│   ├── constants/             # API endpoints, colors, strings
│   ├── network/               # Dio client + interceptors, error mapping
│   ├── router/                # GoRouter config & route paths
│   ├── services/              # Background location, geofence visits, live tracking,
│   │                          # notifications, push, token refresh/storage, uploads
│   ├── theme/                 # Colors, text styles, responsive helpers
│   └── widgets/               # Main shell + bottom nav
└── features/
    ├── auth/                  # Login, session
    ├── dashboard/             # Home summary
    ├── tasks/                 # Task list, detail, history, checklist
    ├── shops/                 # Shop list, detail, stand-at-shop create
    ├── collections/           # Cash/cheque collections + SMS receipt
    ├── geofence/              # Geofence visit models/providers
    ├── tracking/              # Live tracking state
    ├── notifications/         # In-app inbox
    ├── profile/               # Profile + personal details
    ├── legal/                 # Terms & privacy
    └── presentation/screens/  # Splash, onboarding, route, payment, etc.
```

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.11.5`)
- Android Studio / Xcode for device & simulator builds
- A **Mapbox** account with a public access token
- Firebase project config (not included in the repo — add your own):
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

### 1. Configure environment

Create a `.env` file in the project root (an `.env.example` is provided):

```env
MAPBOX_PUBLIC_TOKEN=pk.your_mapbox_public_token
```

> The backend base URL is set in [lib/core/constants/api_constant.dart](lib/core/constants/api_constant.dart) (`https://fieldguard.duckdns.org`).

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate serialization code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run

```bash
flutter run
```

### App launcher icons (optional)

After changing `assets/images/FieldGuard.png`:

```bash
dart run flutter_launcher_icons
```

---

## Build

```bash
# Android
flutter build apk --release        # or: flutter build appbundle --release

# iOS
flutter build ios --release
```

CI is configured for **Codemagic** (see [codemagic.yaml](codemagic.yaml)), including an iOS simulator workflow that copies `.env.example`, runs `build_runner`, and produces a `Runner.app` artifact.

---

## Permissions

The app requests these at runtime as features are used:

- **Location** (foreground + background) — live tracking and geofenced check‑in
- **Notifications** — push and geofence enter/exit alerts
- **Camera / Photos** — image capture for uploads

---

## Backend

The app talks to a REST API (base URL in [api_constant.dart](lib/core/constants/api_constant.dart)) plus a Socket.IO realtime channel. Key endpoint groups: auth, dashboard, tasks, shops, collections, geofence‑visits, uploads (presigned URLs), notifications, and device push‑token registration.
