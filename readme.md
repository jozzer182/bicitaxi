# Bici Taxi – Hybrid Monorepo (Android & iOS)

Bici Taxi is a modern, ride-hailing experience tailored for bike taxis.
This repository follows a **Hybrid Architecture** to leverage the best of both worlds:

-   **Android**: Built with **Flutter** for rapid development and consistency across the fragmented Android ecosystem.
-   **iOS**: Built with **Native SwiftUI** to maximize performance, animations, and integration with Apply system design (iOS 18+).

Both platforms share the same **Liquid Glass** design language—a clean, white, light-themed aesthetic with translucent glass cards, blurred backgrounds, and high-readability typography.

---

## 🏛️ Project Architecture

This monorepo contains four distinct applications organized by platform and role:

| Platform | Tech Stack | Client App (Rider) | Driver App (Conductor) |
| :--- | :--- | :--- | :--- |
| **Android** | **Flutter** | `bicitaxi/flutter/bicitaxi` | `bicitaxi/flutter/bicitaxi_conductor` |
| **iOS** | **Native SwiftUI** | `bicitaxi/ios/BiciTaxi` | `bicitaxi/ios/BiciTaxiConductor` |

### Backend
-   **Firebase Auth**: Secure authentication (Email/Password, Google).
-   **Cloud Firestore**: Real-time database for user profiles, ride requests, and chat.
-   **Firebase Storage**: (Planned) User avatars and documents.

---

## ✨ Key Features

### 🌌 Liquid Glass UI (Light Theme)
Both platforms implement our custom **Liquid Glass** design system:
-   **Light Mode Only**: A bright, clean aesthetic using white and translucent layers.
-   **Glassmorphism**: High-quality blur effects (`BackdropFilter` in Flutter, `UltraThinMaterial` in SwiftUI) for cards and overlays.
-   **GLSL Refraction Shader** (Android/Flutter): Custom fragment shader that creates realistic lens-like distortion, showing the map background through glass panels with:
    - Real-time refraction and distortion
    - Subtle wave animations
    - Fresnel edge glow (brighter at edges like real glass)
    - Dynamic widget position detection
-   **Typography**: Modern, bold headings with readable body text.
-   **Animations**: Fluid transitions and interactive elements.

> 📖 **Implementation Details**: See [flutter/bicitaxi/LIQUID_GLASS.md](flutter/bicitaxi/LIQUID_GLASS.md) for the full shader implementation guide.


### � Core Functionality
-   **Authentication**: Complete flow (Login, Sign Up, Forgot Password, Edit Profile).
-   **Maps & Location**:
    -   **Android**: OpenStreetMap via `flutter_map`.
    -   **iOS**: Native Apple Maps via `MapKit`.
-   **Ride Logic**:
    -   **Client**: Select pickup/dropoff, request ride, view driver status.
    -   **Driver**: Receive requests, accept/reject, navigation, ride completion.
-   **Profile Management**:
    -   Real-time name updates.
    -   Secure password changes.
    -   Account management (Logout, Delete Account).

---

## 🛠️ Technical Implementation

### Android (Flutter)
-   **State Management**: `Provider` / `ChangeNotifier` (AppState).
-   **Architecture**: Repository Pattern (`AuthRepository`, `RideRepository`).
-   **Dependencies**:
    -   `firebase_auth`, `cloud_firestore` (Backend).
    -   `google_sign_in` (Social Auth).
    -   `flutter_map` (Maps).
    -   `liquid_glass_ui` (Custom UI package).

### iOS (Native)
-   **Framework**: SwiftUI + Combine.
-   **Architecture**: MVVM (Model-View-ViewModel).
-   **Dependencies**:
    -   `FirebaseAuth`, `FirebaseFirestore` (Swift Package Manager).
    -   `MapKit` (Native Maps).
-   **Design**: Custom ViewModifiers for "Glass" effects and "Liquid Buttons".

---

## 🚀 Getting Started

### Prerequisites
-   **Flutter SDK**: 3.27+ (for Android).
-   **Xcode**: 16+ (for iOS).
-   **CocoaPods**: (If required for specific Flutter plugins).
-   **Google Services**:
    -   `google-services.json` (Android) placed in `android/app`.
    -   `GoogleService-Info.plist` (iOS) placed in `ios/Runner` (Flutter) and root of Native iOS projects.

### 🤖 Running Android (Flutter)

1.  **Client App**:
    ```bash
    cd flutter/bicitaxi
    flutter pub get
    flutter run
    ```

2.  **Driver App**:
    ```bash
    cd flutter/bicitaxi_conductor
    flutter pub get
    flutter run
    ```

### 🍎 Running iOS (Native)

1.  Open the workspace or project in Xcode:
    -   `ios/BiciTaxi.xcodeproj` (Client)
    -   `ios/BiciTaxiConductor.xcodeproj` (Driver)
2.  Select your target simulator or device.
3.  Hit **Run (Cmd+R)**.

---

## 📂 Directory Structure

```text
.
├── flutter/                        # ANDROID (Flutter Projects)
│   ├── bicitaxi/                   # 🟢 Client App
│   │   ├── lib/
│   │   │   ├── features/           # Auth, Profile, Rides, Map
│   │   │   ├── core/               # Theme, Repositories, Widgets
│   │   └── ...
│   └── bicitaxi_conductor/         # 🔵 Driver App
│       ├── lib/
│       └── ...
│
├── ios/                            # iOS (Native Projects)
│   ├── BiciTaxi/                   # 🟢 Client App (SwiftUI)
│   │   ├── App/
│   │   ├── Core/
│   │   ├── Features/
│   │   └── ...
│   └── BiciTaxiConductor/          # 🔵 Driver App (SwiftUI)
│       └── ...
│
└── README.md
```

---

### 📝 Roadmap / Pending
-   [ ] **Real-time Ride Matching**: Connect Firestore streams to map logic.
-   [ ] **Push Notifications**: FCM integration for ride alerts.
-   [ ] **Chat**: Implement real-time chat using Firestore subcollections.

---

**Developed with ❤️ by the Bici Taxi Team.**
