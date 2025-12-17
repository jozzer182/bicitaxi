# Geo Cells + Presence + Requests System

## Overview

This document describes the implementation of the deterministic geographic cell system for the BiciTaxi presence and request functionality.

## Architecture

### Grid System (30 Arc-Second Cells)

- **Step Size**: 30 arc-seconds (30")
- **Cell Definition**: South-west corner aligned to step boundary
- **Canonical Format**: `LAT_HEMI + latDeg(2) + "_" + latMin(2) + "_" + latSec(2) + "_" + LON_HEMI + lonDeg(3) + "_" + lonMin(2) + "_" + lonSec(2) + "_s" + stepSec(2)`
- **Example**: `N04_44_30_W074_04_30_s30`
- **Cell ID**: Base64url-encoded canonical string (no padding)

### Firestore Data Model

```
/cells/{cellId}/presence/{uid}
  - uid: string
  - role: "driver" | "client"
  - lastSeen: serverTimestamp()
  - expiresAt: timestamp (now + 24h)
  - lat: number
  - lng: number
  - cellId: string
  - activeRideId: string | null
  - platform: "flutter_android" | "ios_native"
  - app: "bicitaxi" | "bicitaxi_conductor"
  - updatedAt: serverTimestamp()

/cells/{cellId}/requests/{requestId}
  - requestId: string
  - createdByUid: string
  - pickup: { lat, lng }
  - dropoff: { lat, lng } | null
  - status: "open" | "assigned" | "cancelled" | "completed"
  - assignedDriverUid: string | null
  - createdAt: serverTimestamp()
  - updatedAt: serverTimestamp()
  - cellId: string
  - expiresAt: timestamp (now + 24h)
```

## Files Created/Modified

### Flutter Client App (`/flutter/bicitaxi/`)

- `lib/core/services/geo_cell_service.dart` - Canonical grid algorithm
- `lib/core/services/presence_service.dart` - Presence management
- `lib/core/services/request_service.dart` - Request management
- `lib/core/widgets/driver_count_overlay.dart` - Driver count UI
- `lib/features/map/presentation/geo_cell_debug_screen.dart` - Debug/test screen
- `lib/features/home/presentation/map_home_screen.dart` - Integrated driver count overlay

### Flutter Driver App (`/flutter/bicitaxi_conductor/`)

- `lib/core/services/geo_cell_service.dart` - Same algorithm
- `lib/core/services/presence_service.dart` - Driver presence
- `lib/core/services/request_service.dart` - Request watching
- `lib/core/widgets/request_list_widget.dart` - Request list UI

### iOS Client App (`/ios/bicitaxi/`)

- `Services/GeoCellService.swift` - Canonical grid algorithm
- `Services/PresenceService.swift` - Presence management
- `Services/RequestService.swift` - Request management
- `Views/Components/DriverCountOverlay.swift` - Driver count UI
- `Views/Map/GeoCellDebugView.swift` - Debug/test view

### iOS Driver App (`/ios/bicitaxi-conductor/`)

- `Services/GeoCellService.swift` - Same algorithm
- `Services/PresenceService.swift` - Driver presence
- `Services/RequestService.swift` - Request watching
- `Views/Components/RequestListView.swift` - Request list UI

### Firestore Security Rules

Deployed to `bicitaxicol` project:
- Authenticated users can read all presence/requests
- Users can only write their own presence (uid match)
- Users can only create requests they own
- Creators and assigned drivers can update requests

## Test Vectors

Use these coordinates to verify cross-platform consistency:

| Location | Lat | Lng | Expected Canonical |
|----------|-----|-----|-------------------|
| Suba Center (Bogotá) | 4.7410 | -74.0721 | `N04_44_00_W074_04_00_s30` |
| Near Equator | 0.5 | 0.5 | `N00_30_00_E000_30_00_s30` |
| Buenos Aires | -34.6037 | -58.3816 | `S34_36_00_W058_22_30_s30` |
| Madrid | 40.4168 | -3.7038 | `N40_25_00_W003_42_00_s30` |

## How to Test

### Flutter

```dart
// In any Flutter file, call:
import 'package:bicitaxi/core/services/geo_cell_service.dart';

GeoCellTestVectors.runAllTests();
```

Or navigate to the GeoCellDebugScreen.

### iOS

```swift
// In any Swift file, call:
GeoCellTestVectors.runAllTests()
```

Or use the GeoCellDebugView.

## Presence System

### Client Behavior
1. On login, start location tracking
2. Update presence every 3 minutes in current cell
3. Subscribe to driver count in current cell + 8 neighbors
4. Display "X conductores en tu zona" on map

### Driver Behavior
1. On login, start location tracking
2. Update presence every 3 minutes (role="driver")
3. Subscribe to open requests in current cell
4. After 20 seconds, expand to 9 cells if no requests

### Stale Filtering
- Filter by `lastSeen >= now - 10 minutes`
- Do NOT delete stale docs from client
- TTL policy handles cleanup (24h expiration)

## TTL Configuration

TTL policies should be configured via Firebase Console:
- `/cells/{cellId}/presence/{uid}` by field `expiresAt`
- `/cells/{cellId}/requests/{requestId}` by field `expiresAt`

Note: TTL is for cost control only, not real-time presence correctness.

## Security Rules Summary

```
/cells/{cellId}/presence/{uid}
  - read: auth != null
  - create/update/delete: auth.uid == uid

/cells/{cellId}/requests/{requestId}
  - read: auth != null
  - create: auth.uid == createdByUid
  - update: auth.uid == createdByUid OR auth.uid == assignedDriverUid
  - delete: auth.uid == createdByUid
```

## Next Steps

1. **Testing**: Run both apps and verify driver count updates in real-time
2. **TTL**: Configure TTL policies in Firebase Console
3. **Request Flow**: Implement full accept/complete flow for drivers
4. **Notifications**: Add push notifications for new requests
5. **Rate Limiting**: Add rate limiting for request creation
