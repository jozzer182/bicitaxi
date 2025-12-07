# Bici Taxi – Dual Flutter App (Client & Driver)

Bici Taxi is a minimal, modern ride-hailing experience tailored for bike taxis.  
Instead of cars and complex options, Bici Taxi focuses on **one thing done well**: connecting riders with local bike-taxi drivers in a clean, fast, and beautiful mobile experience.

This repository contains **two Flutter apps**:

- **Bici Taxi** – the **client** app (riders)
- **Bici Taxi Conductor** – the **driver** app (bike-taxi drivers)

Both apps share the same design language, use a Liquid Glass-inspired UI, and are ready to be connected to a Firebase backend.

---

## Key Features

### 🌌 Liquid Glass UI Design
- Strong use of **`liquid_glass_renderer`** and **`liquid_glass_ui_design`**.
- Dark primary theme with glass cards and overlays.
- Carefully tuned for **readability + aesthetics** (no “just another Material app” feeling).

### 📱 Built for Phones and Tablets
- First-class support for:
  - Android phones & tablets
  - iPhone & iPad
- Responsive layouts:
  - Bottom navigation on smaller screens.
  - Side navigation / wider layouts on tablets.
  - Constrained content width for a more “app-like” look on large devices.

### 🗺️ OpenStreetMap Integration
- Map powered by **`flutter_map`** using **OpenStreetMap** tiles.
- No Google Maps dependency.
- Location handled via:
  - `geolocator`
  - `permission_handler`
- Behavior:
  - Client: select pickup and dropoff directly on the map.
  - Driver: view own position and dummy nearby requests.

### 🚲 Ride Flow (Front-End Logic)
**Client App (Bici Taxi):**
- Pick pickup + dropoff on map.
- Request a ride (front-end only).
- See an **Active Ride** screen with status changes.
- View a **History** of completed rides (from an in-memory repository).

**Driver App (Bici Taxi Conductor):**
- See a list of **pending ride requests** (dummy, generated locally).
- Accept a ride and move through statuses:
  - Assign → Arriving → In Progress → Completed.
- View a simple **earnings summary** based on completed rides.

All ride logic uses **pure Dart models** and repositories designed to be **Firebase-ready** (no backend wired yet).

### 💬 In-Ride Chat (Local / Demo)
- Simple, structured chat between client and driver, per ride:
  - Chat messages stored in an in-memory chat repository.
  - `ChatMessage` model is designed to match a future Firestore schema.
- Liquid Glass chat screen:
  - Bubble-based UI (left/right alignment).
  - Works nicely on both phones and tablets.
- Currently **local-only**, but structure is ready for real-time backend integration.

### 🔥 Firebase-Ready Models (But No Backend Yet)
- Ride models, chat models, and repositories are implemented with:
  - `toMap()` / `fromMap()` using only primitives.
  - `DateTime` stored as `millisecondsSinceEpoch`.
- Comments (`TODO`) mark the exact places where:
  - Firebase Auth
  - Firestore collections
  - Real-time streams  
  can be plugged in without redesigning the app.

---

## Tech Stack

- **Framework:** Flutter 3.38.4
- **Languages:** Dart, Kotlin (minimal Android host), Swift (iOS host if needed)
- **UI:**
  - `liquid_glass_renderer`
  - `liquid_glass_ui_design`
- **Maps:**
  - `flutter_map`
  - `latlong2`
- **Location & Permissions:**
  - `geolocator`
  - `permission_handler`
- **Icons:**
  - `flutter_launcher_icons`
  - Icons stored in each app’s `/icons` folder and generated for Android/iOS.

---

## Project Structure

Repository root (simplified):

```text
.
├─ README.md
├─ bicitaxi/                  # Client app (riders)
│  ├─ android/
│  ├─ ios/
│  ├─ lib/
│  │  ├─ core/
│  │  │  ├─ theme/
│  │  │  └─ widgets/
│  │  ├─ features/
│  │  │  ├─ auth/
│  │  │  ├─ home/
│  │  │  ├─ map/
│  │  │  ├─ rides/
│  │  │  └─ chat/
│  └─ icons/
└─ bicitaxi_conductor/        # Driver app (bike-taxi drivers)
   ├─ android/
   ├─ ios/
   ├─ lib/
   │  ├─ core/
   │  ├─ features/
   │  │  ├─ auth/
   │  │  ├─ home/
   │  │  ├─ map/
   │  │  ├─ rides/
   │  │  └─ chat/
   └─ icons/
```

Each app has its own:

- `main.dart`
- Theme configuration
- Routes
- Features (auth, map, rides, chat), mirrored but with role-specific behavior.

---

## Getting Started

### Prerequisites

- **Flutter 3.38.4** installed and configured.
- **Android Studio / SDK** set up for Android builds.
- **Xcode** (if you want to run on iOS).
- A device or emulator (Android or iOS).

### 1. Clone the repo

```bash
git clone https://github.com/<your-user>/bici-taxi.git
cd bici-taxi
```

### 2. Run the Client App (Bici Taxi)

```bash
cd bicitaxi
flutter pub get
flutter run
```

> This will launch the **client** app (rider side) on the connected device/emulator.

### 3. Run the Driver App (Bici Taxi Conductor)

In another terminal:

```bash
cd bicitaxi_conductor
flutter pub get
flutter run
```

> This launches the **driver** app so you can test flows in parallel.

---

## Building Android APKs

From each app’s root:

### Client APK

```bash
cd bicitaxi
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

APK path:

```text
bicitaxi/build/app/outputs/flutter-apk/app-release.apk
```

### Driver APK

```bash
cd bicitaxi_conductor
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

APK path:

```text
bicitaxi_conductor/build/app/outputs/flutter-apk/app-release.apk
```

You can rename them as:

- `bicitaxi_client.apk`
- `bicitaxi_conductor.apk`

for easier sharing and testing.

---

## Roadmap

Planned next steps:

- 🔐 **Firebase Auth**  
  - Sign in with Google & Apple.
  - Proper user accounts for client and driver.

- ☁️ **Firestore Backend**
  - Persist rides (creation, assignment, status updates).
  - Persist chat messages per ride.
  - Real-time updates for driver availability and ride status.

- 💸 **Payment & Rating (Future)**
  - Basic rating system for rides.
  - Payment integration (if required by the product scope).

- 🌎 **Production Hardening**
  - Better error handling and empty states.
  - Analytics events (start ride, cancel, completed, etc.).
  - Theming variations for different markets.

---

## Why Bici Taxi?

Most ride-hailing apps are heavy, complex, and tuned for cars.  
**Bici Taxi** is intentionally:

- **Lightweight** – fast to open, easy to understand.
- **Focused** – no unnecessary clutter or endless options.
- **Designed for bikes** – short-distance, urban, human-scale transportation.

It’s a solid starting point if you want to:

- Launch a local bike-taxi service.
- Prototype mobility ideas.
- Learn real-world Flutter architecture with dual apps (client + driver) sharing concepts but with different flows.

---

## License

You can adapt this section based on how you want to license the project (MIT, Apache 2.0, proprietary, etc.).

```text
Copyright (c) <Your Name>

All rights reserved.
```

---

If you build something cool on top of Bici Taxi or ship it to production, feel free to mention it in your docs or portfolio – this project is meant to be both a **real product seed** and a **showcase of Flutter capabilities**.
