# iOS Native Apps - Bici Taxi

This folder contains the **native iOS implementations** for both Bici Taxi apps, built with **SwiftUI** and targeting **iOS 26** with Apple's new **Liquid Glass** design language.

## Contents

- `bicitaxi/` - Client app (riders)
- `bicitaxi-conductor/` - Driver app (conductors)

---

## 🧊 iOS 26 Liquid Glass Implementation

### Overview

We implemented the **native iOS 26 TabView** with Apple's new `Tab` syntax, which automatically applies the system's Liquid Glass material styling. This approach uses Apple's built-in tab bar with native Liquid Glass effects, rather than a custom implementation.

### Key Components

#### LiquidGlassTabShell.swift
Native SwiftUI TabView using iOS 18+ Tab-based syntax:
- **Native TabView**: Uses `TabView(selection:)` with iOS 26's automatic Liquid Glass styling
- **Tab syntax**: New `Tab(title, systemImage:, value:)` API for cleaner tab definitions
- **Automatic styling**: iOS 26 applies Liquid Glass material to the tab bar automatically
- **Tab bar style**: Uses `.tabViewStyle(.tabBarOnly)` for standard tab bar behavior

#### Native Tab Implementation

```swift
// iOS 26 Native TabView with automatic Liquid Glass
TabView(selection: $selectedTab) {
    Tab("Mapa", systemImage: "map.fill", value: .map) {
        ClientMapView(rideViewModel: rideViewModel)
    }
    
    Tab("Viaje", systemImage: "bicycle", value: .activeRide) {
        ActiveRideView(rideViewModel: rideViewModel, onComplete: { ... })
    }
    
    Tab("Perfil", systemImage: "person.fill", value: .profile) {
        ProfileView(rideViewModel: rideViewModel)
    }
}
.tabViewStyle(.tabBarOnly)
```

---

## 📚 iOS 26 glassEffect API Reference

### Glass Style Variants

| Variant | Description | Blur Level |
|---------|-------------|------------|
| `.regular` | Default system glass, stronger tint | High |
| `.clear` | Most transparent option | Lower |
| `.identity` | No glass effect (disabled) | None |

### Available Modifiers

| Modifier | Purpose |
|----------|---------|
| `.interactive()` | Responds to touch/pointer |
| `.tint(Color)` | Blend a color into the glass |

### Example Usage

```swift
RoundedRectangle(cornerRadius: 16)
    .fill(.clear)
    .glassEffect(
        .clear.interactive().tint(.blue),
        in: RoundedRectangle(cornerRadius: 16)
    )
```

---

## ⚠️ Limitations & Findings

### 1. Blur Cannot Be Fully Removed
The `.glassEffect()` modifier **inherently includes blur** as part of the Liquid Glass material. Even `.clear` (the most transparent variant) has some blur effect.

**Apple's own apps** (like Apple News) may use internal/private APIs that provide finer control over blur intensity that is not exposed to third-party developers.

### 2. iOS 26.1 Transparency Options (Coming Soon)
Apple is testing an **adjustable Liquid Glass transparency feature** in iOS 26.1:
- "Clear" mode: More translucent
- "Tinted" mode: More opaque

This confirms Apple recognized the need for more transparency control.

### 3. Metal Shaders ≠ glassEffect Control
While Metal shaders provide fine-grained control over custom blur and refraction effects, they **cannot directly modify** the iOS 26 `.glassEffect()` parameters. They are separate rendering systems.

Metal **can be used for**:
- Custom distortion/refraction effects on icons
- Pixel-level lens manipulation
- Custom blur implementations

Metal **cannot**:
- Reduce the built-in blur of `.glassEffect()`
- Access internal glass material properties

### 4. GlassEffectContainer for Morphing
To enable fluid morphing animations between glass elements:

```swift
GlassEffectContainer {
    // Glass views morph together
    Capsule()
        .fill(.clear)
        .glassEffect(.regular.interactive(), in: .capsule)
}
```

---

## 🔗 Sources & References

### Apple Official Documentation
- [Apple Developer - Liquid Glass Design](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SwiftUI glassEffect Modifier](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)

### Technical Articles
- [Swift with Majid - Glass Effect in SwiftUI](https://swiftwithmajid.com/) - Detailed exploration of glass variants
- [Livsycode - iOS 26 Liquid Glass Tutorial](https://livsycode.com/) - Implementation examples
- [Create with Swift - Glass Effects](https://createwithswift.com/) - Shape customization guide

### News & Updates
- [MacRumors - iOS 26 Liquid Glass](https://www.macrumors.com/) - Feature announcements
- [AppleInsider - visionOS-Inspired Design](https://appleinsider.com/) - Design language analysis
- [Houston Chronicle - iOS 26.1 Transparency Options](https://www.houstonchronicle.com/) - Upcoming adjustable transparency

### Community Resources
- [Medium - Metal Shader Blur Control](https://medium.com/) - Custom blur implementations
- [Stack Overflow - UITabBar Transparency](https://stackoverflow.com/) - UIKit approaches
- [Dev.to - Liquid Glass Implementation](https://dev.to/) - Cross-platform considerations

---

## 🎯 Implementation Summary

### What We Achieved
✅ **Native iOS 26 TabView** with automatic Liquid Glass material  
✅ Clean `Tab(title, systemImage:, value:)` syntax  
✅ System-managed tab bar styling and animations  
✅ Proper tab switching with state management  
✅ Automatic navigation to Active Ride tab when ride is requested  
✅ Spanish localization for all tab labels  

### Notes
ℹ️ iOS 26 applies Liquid Glass styling automatically to native TabView  
ℹ️ No custom implementation needed - Apple provides the glass effect  
ℹ️ Uses `.tabViewStyle(.tabBarOnly)` to prevent sidebar adaptation on iPad  

---

## 📁 File Structure

```
ios/
├── README.md                          # This file
├── bicitaxi/                          # Client app
│   └── bicitaxi/
│       ├── LiquidGlassTabShell.swift # Native TabView container
│       ├── MainTabView.swift         # App entry point
│       ├── AppTab.swift              # Tab enum definitions
│       ├── BiciTaxiTheme.swift       # Theme/colors
│       ├── ClientMapView.swift       # Map with route display
│       ├── ActiveRideView.swift      # Ride tracking
│       └── ProfileView.swift         # User profile with logout/delete
└── bicitaxi-conductor/                # Driver app
    └── bicitaxi-conductor/
        ├── LiquidGlassTabShell.swift # Native TabView (mirrors client)
        └── ... (mirrors client structure)
```

---

## 🛠️ Build Requirements

- **Xcode 26+** (iOS 26 SDK)
- **iOS 26.0+** deployment target
- **Swift 6.0+**

### Build Commands

```bash
# Client app
cd ios/bicitaxi
xcodebuild -project bicitaxi.xcodeproj -scheme bicitaxi \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Driver app
cd ios/bicitaxi-conductor
xcodebuild -project bicitaxi-conductor.xcodeproj -scheme bicitaxi-conductor \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## 📝 Known Issues

1. **CLGeocoder Deprecation**: iOS 26 deprecates `CLGeocoder` in favor of MapKit's `MKReverseGeocodingRequest`. Migration pending.

2. **Glass Blur Intensity**: The `.clear` variant still has inherent blur. This is a public API limitation, not a bug in our implementation.

---

*Last updated: December 2024*  
*iOS 26 Beta / Xcode 26 Beta*
