---
trigger: always_on
---

WORKSPACE RULES – Flutter (Bici Taxi)

You are working in a monorepo that contains BOTH Flutter and native iOS projects.

Always register every prompt and summary of answer and changes made on agent_memory.json on root of this project, 

REPO STRUCTURE (VERY IMPORTANT)
- From the workspace root, the relevant folders are:

  /flutter/
    /bicitaxi/              → Flutter client app (riders)
    /bicitaxi_conductor/    → Flutter driver app (bike-taxi drivers)

  /iOS/
    /bicitaxi/              → Native iOS client app (Swift, Xcode)
    /bicitaxi_conductor/    → Native iOS driver app (Swift, Xcode)

GLOBAL RULE:
- You MUST NOT modify anything inside `/iOS`.
- You MAY open/read the iOS projects for reference, but you must NOT change or delete files under `/iOS` for any reason in these Flutter prompts.
- All changes for these prompts must be applied ONLY under `/flutter/bicitaxi` and `/flutter/bicitaxi_conductor`.

ENVIRONMENT & TOOLS
- Operating system: Windows 11.
- Shell: PowerShell.
- Flutter version: Flutter 3.38.4 (assume this is already installed and configured).
- When you refer to commands, they MUST be compatible with Windows + PowerShell.
  - Examples: `cd`, `dir`, `flutter clean`, `flutter pub get`, `flutter run`, `flutter build apk`, etc.

FLUTTER PROJECTS SUMMARY
- Flutter client app:
  - Path: `/flutter/bicitaxi`
  - Display name: “Bici Taxi”
  - Android applicationId: typically `dev.zarabanda.bicitaxi`
  - iOS bundle ID: typically `dev.zarabanda.bicitaxi`
  - Purpose: rider-facing app.

- Flutter driver app:
  - Path: `/flutter/bicitaxi_conductor`
  - Display name: “Bici Taxi Conductor”
  - Android applicationId: typically `dev.zarabanda.bicitaxi_conductor`
  - iOS bundle ID: typically `dev.zarabanda.bicitaxiConductor`
  - Purpose: driver-facing app.

- Both Flutter apps:
  - Are standard Flutter projects (created from `flutter create` at some point).
  - Already contain a `pubspec.yaml`, Android and iOS folders, and a `lib/` folder with Dart code.
  - Have an `icons/` folder at the project root used for launcher icons.

PLATFORMS & BUILD TARGETS
- Primary target for these prompts: Android (APK builds on Windows).
- The Flutter code should remain compatible with both:
  - Android.
  - iOS (even if iOS builds are typically done from macOS).

ICONS & BRANDING
- Each Flutter project has:
  - `/flutter/bicitaxi/icons/`
  - `/flutter/bicitaxi_conductor/icons/`

APP IDENTIFIERS & NAMES
- Respect existing app IDs unless a prompt explicitly instructs you to change them.
  - Android:
    - `applicationId` in `android/app/build.gradle` (or Gradle KTS equivalent).
  - iOS:
    - `bundleId` set in the iOS subproject (Xcode side; generally not changed from Windows).
- Display names should remain:
  - Client: `Bici Taxi`
  - Driver: `Bici Taxi Conductor`

- Do NOT randomly rename Android/iOS packages, product names or targets without explicit instructions.

LIQUID GLASS FOCUS (FLUTTER)
- The Flutter apps are designed to explore a **Liquid Glass** visual style using packages such as:
  - `liquid_glass_renderer`
  - `liquid_glass_ui_design`
- When implementing or changing UI:
  - Prefer glass-like components (blur, translucency, soft edges) using these packages.

COLOR PALETTE (REFERENCE)
- Primary background: `#0B0016`
- Accent colors:
  - `#4BB3FD`
  - `#3E6680`
  - `#0496FF`
  - `#027BCE`

CODE ORGANIZATION & QUALITY
- You SHOULD:
  - Keep the projects building successfully on Windows:
    - `flutter clean`
    - `flutter pub get`
    - `flutter analyze`
  - Fix analyzer errors and obvious warnings created by your changes.
  - Maintain a clear folder structure, e.g.:
    - `lib/core/…`, `lib/features/auth/…`, `lib/features/map/…`, `lib/features/rides/…`, `lib/features/chat/…`, etc.
  - Use Dart best practices (null-safety, type safety, proper imports).

- You MUST NOT:
  - Delete or recreate the Flutter projects from scratch.
  - Introduce large, unrelated dependencies without a clear reason.
  - Break existing flows (login, navigation, map, ride flows, chat) unless explicitly asked to refactor them.

INTERACTION WITH FLUTTER DEPENDENCIES
- Keep `pubspec.yaml` consistent and valid:
  - Add dependencies only when needed.
  - Run `flutter pub get` after modifying `pubspec.yaml`.
- Use versions compatible with Flutter 3.38.4.
- If a dependency or version conflict arises:
  - Describe the required changes clearly (e.g. version constraints, dependency overrides).
  - Ensure the final `pubspec.yaml` resolves and `flutter analyze` passes.

RUNTIME & DEBUGGING
- When asked to build or run:
  - Use PowerShell commands from the project root, e.g.:

    - For client app:
      - `cd flutter\bicitaxi`
      - `flutter clean`
      - `flutter pub get`
      - `flutter run` (for debugging)
      - `flutter build apk --release` (for release APK)

    - For driver app:
      - `cd flutter\bicitaxi_conductor`
      - Same sequence of commands.

- If you foresee runtime exceptions (null access, layout errors, etc.):
  - Adjust the code to avoid such crashes.
  - When relevant, mention how to inspect logs (e.g. `flutter run` output, `adb logcat`).

ANDROID APK OUTPUTS
- When building APKs:
  - Default output path:
    - `build/app/outputs/flutter-apk/app-release.apk`
  - If a prompt asks to rename/copy:
    - Use PowerShell commands like:
      - `Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "..\bicitaxi_client.apk" -Force`
      - `Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "..\bicitaxi_conductor.apk" -Force`
    - Adapt names according to the instructions in that specific prompt.

INTERACTION WITH EXISTING CODE & PROMPTS
- Before adding new models, services or widgets:
  - Inspect existing files to reuse or extend them when appropriate.
  - Keep naming conventions consistent between client and driver apps.

- Follow these principles:
  - Prefer **incremental changes** (extend existing architecture) instead of rewriting everything.
  - Keep the **client** and **driver** apps conceptually aligned where it makes sense (similar models, similar structures), but allow role-specific behaviors.

SAFETY & SCOPE
- Scope of these Flutter prompts:
  - Only modify code/config under:
    - `/flutter/bicitaxi`
    - `/flutter/bicitaxi_conductor`
- Treat `/iOS` as read-only when working in Flutter phase.
- Ensure that:
  - After your changes, both Flutter apps:
    - Build successfully (`flutter build apk` at minimum).
    - Pass `flutter analyze`.
    - Maintain the flows that have been defined (login, maps, ride logic, chat, bottom navigation) unless explicitly instructed otherwise.

SUMMARY
- Work ONLY in `/flutter/bicitaxi` and `/flutter/bicitaxi_conductor` for Flutter tasks.
- Treat `/iOS` as read-only for these prompts.
- Use Flutter 3.38.4, Windows 11, PowerShell-compatible commands.
- Preserve and extend the Liquid Glass design in Flutter using the given packages and palette.
- Keep both apps buildable, analyzable and free of new runtime crashes in the flows you touch.
