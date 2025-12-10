---
trigger: always_on
---

WORKSPACE RULES – iOS (Bici Taxi)

You are working in a monorepo that contains BOTH Flutter and native iOS projects.

REPO STRUCTURE (VERY IMPORTANT)
- From the workspace root, the relevant folders are:

  /flutter/
    /bicitaxi/              → Flutter client app (Android/iOS)
    /bicitaxi_conductor/    → Flutter driver app (Android/iOS)

  /iOS/
    /bicitaxi/              → Native iOS client app (“Bici Taxi”) in Swift
    /iOS/bicitaxi/icons/    → App icon assets for the client iOS app

    /bicitaxi_conductor/    → Native iOS driver app (“Bici Taxi Conductor”) in Swift
    /iOS/bicitaxi_conductor/icons/ → App icon assets for the driver iOS app

GLOBAL RULE:
- You MUST NOT modify anything inside `/flutter`.
- You MAY open/read the Flutter projects for reference (naming, flows, etc.), but you must NOT change or delete files under `/flutter` for any reason in these iOS prompts.

ENVIRONMENT & TOOLS
- Operating system: macOS Sequoia 15.7.2 (Intel CPU).
- Xcode version: Xcode 26.1.1
- the only testing device avaible is iPhone 17 (made) (46754DEC-0615-4477-B7FB-0BEFAEA63D13) (Booted)
- Language: Swift (SwiftUI or UIKit depending on how each project was created).
- When you refer to shell commands, assume the user is using zsh in the macOS terminal.
- Only use commands that are safe for macOS (e.g. `cd`, `ls`, `xcodebuild`, `swift`, etc.).

IOS PROJECTS SUMMARY
- Native iOS client app:
  - Path: `/iOS/bicitaxi`
  - Display name: “Bici Taxi”
  - Purpose: rider-facing client app.

- Native iOS driver app:
  - Path: `/iOS/bicitaxi_conductor`
  - Display name: “Bici Taxi Conductor”
  - Purpose: driver-facing app for bike-taxi drivers.

- Both iOS apps:
  - Are Xcode 26 projects created from scratch in Swift.
  - May use SwiftUI or UIKit templates; you must detect which is in use and respect that:
    - If it is SwiftUI-based (App protocol with `@main`), stay with SwiftUI.
    - If it is UIKit-based (AppDelegate/SceneDelegate + ViewControllers), stay with UIKit.

PLATFORMS & DEVICES
- Target platforms: iOS only (for these native projects).
- Target devices:
  - iPhone (portrait and landscape).
  - iPad (portrait and landscape).
- Your layouts should be responsive:
  - On iPhone: bottom navigation, compact layouts.
  - On iPad: centered content or adapted layouts with sensible maxWidth constraints.

LIQUID GLASS FOCUS
- The main visual identity of these iOS apps is **Liquid Glass**:
  - Heavy use of https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass 
  - Glass-like cards, overlays, and navigation bars.
- Whenever you build or change UI:
  - Prefer Liquid Glass components.
  - Smooth, fluid transitions that visually feel “liquid”.
-Color Palette: white theme and #0B0016, #4BB3FD, #3E6680, #0496FF, #027BCE

NAMING, IDS & BUNDLE IDENTIFIERS
- Use the existing bundle identifiers unless explicitly instructed to change them.
- Typical pattern (do NOT alter unless a prompt explicitly says so):
  - Client iOS app: `dev.zarabanda.bicitaxi.ios`
  - Driver iOS app: `dev.zarabanda.bicitaxiConductor.ios`
- Do not randomly rename targets, schemes, or product names without a clear reason.

CODE QUALITY & SAFETY
- You must:
  - Keep the projects building successfully in Xcode (no compilation errors).
  - Avoid introducing runtime crashes (e.g. unwrapping nil unsafely).
  - Keep code organized (group related files: Models, ViewModels/Controllers, Views, Services, etc.).
- You may:
  - Add small helper types (e.g. theme structs, services).
  - Add TODO comments specifically for future backend integration (e.g. Firebase, REST API).
- You should NOT:
  - Introduce heavy dependencies unless explicitly requested.
  - Perform breaking refactors of the entire project unless the prompt clearly demands it.

INTERACTION WITH EXISTING CODE
- Before adding new structures, quickly inspect existing files to:
  - Reuse existing types when appropriate.
  - Keep naming consistent (tabs, screens, ride models, etc.).
- Favor incremental changes:
  - Extend or adapt the current structure rather than rewriting everything.

FLOW & TESTING
- When asked to implement features, always:
  - Make sure the app builds.
  - Run it on at least one iPhone simulator (e.g. iPhone 17).
  - When relevant, also consider iPad simulators to verify layout.
- Do NOT silently ignore errors or warnings:
  - If a build error would occur, you must describe how to fix the code or configuration in detail.

SUMMARY
- Work ONLY under `/iOS/bicitaxi` and `/iOS/bicitaxi_conductor` for native iOS changes.
- Treat `/flutter` as read-only reference.
- Use Swift (SwiftUI or UIKit according to each project).
- Preserve and enhance the Liquid Glass design language.
- Maintain clean, buildable projects with no crashes for the flows you touch.