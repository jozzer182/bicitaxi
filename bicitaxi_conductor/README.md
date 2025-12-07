# 🚴 BiciTaxi Driver - Driver App

Mobile application for bicycle taxi service drivers. Receive ride requests, manage routes, and track your earnings.

## 📱 Screenshots

_Coming soon..._

## ✨ Features

- 🗺️ **Real-time Map** - View nearby ride requests
- 📥 **Ride Reception** - Accept or decline customer requests
- 🧭 **Integrated Navigation** - Guidance to pickup point and destination
- 💬 **Customer Chat** - Direct communication during rides
- 💰 **Earnings Tracking** - Daily/weekly/monthly income monitoring
- 👤 **Driver Profile** - Manage your information and availability
- 🔐 **Secure Authentication** - Verified login

## 🏗️ Architecture

```
lib/
├── core/
│   ├── providers/      # Global app state
│   ├── routes/         # Navigation configuration
│   ├── theme/          # App colors and styles
│   └── widgets/        # Reusable widgets
├── features/
│   ├── auth/           # Authentication (login, register)
│   ├── chat/           # Customer messaging system
│   ├── earnings/       # Earnings management and statistics
│   ├── home/           # Driver home screen
│   ├── map/            # Map and location services
│   ├── profile/        # Driver profile
│   └── rides/          # Active ride management
└── main.dart
```

## 🛠️ Tech Stack

| Package                  | Purpose                             |
| ------------------------ | ----------------------------------- |
| `flutter_map`            | Interactive maps with OpenStreetMap |
| `geolocator`             | Real-time GPS location services     |
| `latlong2`               | Geographic coordinate handling      |
| `permission_handler`     | Device permission management        |
| `liquid_glass_ui_design` | Glass effect UI design              |

## 🚀 Installation

### Prerequisites

- Flutter SDK ^3.10.3
- Dart SDK ^3.10.3
- Android Studio / Xcode (for emulators)

### Steps

1. Clone the repository:

```bash
git clone https://github.com/jozzer182/bicitaxi.git
cd bicitaxi/bicitaxi_conductor
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the application:

```bash
flutter run
```

## 📋 Additional Configuration

### Required Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

- `ACCESS_FINE_LOCATION` - Precise location (critical for drivers)
- `ACCESS_COARSE_LOCATION` - Approximate location
- `ACCESS_BACKGROUND_LOCATION` - Background location
- `INTERNET` - Internet connection
- `FOREGROUND_SERVICE` - Foreground service

**iOS** (`ios/Runner/Info.plist`):

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes` → `location`

### Firebase (Coming Soon)

The app is ready for Firebase integration:

- Authentication (driver verification)
- Cloud Firestore (ride and earnings data)
- Cloud Messaging (new ride notifications)
- Realtime Database (real-time location)

## 🧪 Tests

```bash
flutter test
```

## 📊 Driver Features Status

| Feature                        | Status         |
| ------------------------------ | -------------- |
| View map with current location | ✅             |
| Receive ride requests          | 🔄 In progress |
| Accept/decline rides           | 🔄 In progress |
| Navigation to customer         | 🔄 In progress |
| Customer chat                  | ✅             |
| Ride history                   | ✅             |
| Earnings dashboard             | ✅             |
| Available/unavailable mode     | 🔄 In progress |

## 📄 License

This project is private and under development.

---

**Part of the [BiciTaxi](https://github.com/jozzer182/bicitaxi) monorepo**
