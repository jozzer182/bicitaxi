# 🚲 BiciTaxi - Client App

Mobile application for bicycle taxi service customers. Request rides, view nearby drivers, and manage your ride history.

## 📱 Screenshots

_Coming soon..._

## ✨ Features

- 🗺️ **Interactive Map** - View your location and available drivers in real-time
- 📍 **Ride Requests** - Select pickup and destination to request a bicitaxi
- 💬 **Real-time Chat** - Communicate directly with your driver
- 📊 **Ride History** - View all your previous rides
- 👤 **User Profile** - Manage your personal information
- 🔐 **Secure Authentication** - Login and registration

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
│   ├── chat/           # Messaging system
│   ├── home/           # Client home screen
│   ├── map/            # Map and location services
│   ├── profile/        # User profile
│   └── rides/          # Ride request and management
└── main.dart
```

## 🛠️ Tech Stack

| Package                  | Purpose                             |
| ------------------------ | ----------------------------------- |
| `flutter_map`            | Interactive maps with OpenStreetMap |
| `geolocator`             | GPS location services               |
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
cd bicitaxi/bicitaxi
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

- `ACCESS_FINE_LOCATION` - Precise location
- `ACCESS_COARSE_LOCATION` - Approximate location
- `INTERNET` - Internet connection

**iOS** (`ios/Runner/Info.plist`):

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

### Firebase (Coming Soon)

The app is ready for Firebase integration:

- Authentication
- Cloud Firestore
- Cloud Messaging (push notifications)

## 🧪 Tests

```bash
flutter test
```

## 📄 License

This project is private and under development.

---

**Part of the [BiciTaxi](https://github.com/jozzer182/bicitaxi) monorepo**
