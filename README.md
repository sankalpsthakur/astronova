# CosmoChat Swift Packages

CosmoChat is broken down into several independent Swift packages so each module can be developed and tested in isolation.
The packages use **Swift Package Manager** and therefore can be opened directly in Xcode or built from the command line.

## Requirements

- **Swift** 5.10
- **Xcode** 15 or later (needed to build targets that rely on Apple frameworks such as CloudKit)

## Opening and Building

1. Launch **Xcode 15+**.
2. Choose **File → Open...** and select any package directory (e.g. `AppCore`).
3. Xcode detects the `Package.swift` manifest and sets up the project.
4. Build or test inside Xcode or run `swift build` / `swift test` from the package directory in Terminal.

## Repository Structure

Each folder below contains its own `Package.swift`, a `Sources/` directory with the library code and a matching `Tests/` directory.

- **AppCore**
  - Hosts the `CosmicApp` entry point and main SwiftUI views such as `RootView` and the tab bar.
  - Wires together submodules including authentication, horoscope fetching, notifications and in‑app purchases.
- **AstroEngine**
  - Implements astrology calculations (`LoShuCalc`, `VedicKundaliCalc`, `WesternCalc`).
  - Provides `MatchService` for compatibility matching using the Swiss Ephemeris.
- **AuthKit**
  - Apple sign‑in coordination (`AppleSignInCoordinator`) and CloudKit authentication helpers.
  - Stores credentials securely via `KeychainHelper`.
- **CloudKitKit**
  - Thin wrappers around CloudKit APIs (`CKContainer+Cosmic`, `CKDatabaseProxy`, `CKQueryBuilder`).
- **CommerceKit**
  - Handles StoreKit and Apple Pay integration with helpers like `StoreKitPlusManager` and `OrderRepository`.
- **DataModels**
  - Shared model types (`UserProfile`, `Horoscope`, `Order`, etc.) and `CKRecordConvertible` utilities.
- **HoroscopeService**
  - Fetches and caches daily horoscopes with `HoroscopeRepository` and manages saved matches.
- **NotificationKit**
  - Schedules local and push notifications (`DailyScheduler`, `PushCoordinator`).
- **SettingsKit**
  - Manages language and notification preferences via `SettingsViewModel` and related helpers.
- **SwissEphemeris**
  - Minimal wrapper that exposes necessary functions from the Swiss Ephemeris C library.
- **UIComponents**
  - Reusable SwiftUI views such as `CalcForm` and `ZodiacCard` used across the app.

## Running Tests

Tests live in each package's `Tests/` directory. To run them:

```bash
cd <PackageName>
swift test
```

Packages that depend on Apple frameworks must be tested on macOS with Xcode installed.
