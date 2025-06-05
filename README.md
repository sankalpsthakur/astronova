# CosmoChat Swift Packages

CosmoChat is organized as several independent Swift packages. The packages use Swift Package Manager and can be opened in Xcode as needed.

## Requirements

- **Swift**: 5.10
- **Xcode**: 15 or later

## Opening and Building

1. Launch Xcode 15+.
2. Choose **File > Open...** and select the directory of the package you want to work on (for example `AppCore`).
3. Xcode will load the `Package.swift` and allow you to build or run tests within that package.
4. Alternatively, from the command line you can run `swift build` inside each package directory.

## Directory Overview

- `AppCore` – Main application logic and SwiftUI views.
- `AstroEngine` – Astrology calculations (Lo Shu, Vedic, Western) and matching logic.
- `AuthKit` – Authentication helpers for Apple sign‑in and CloudKit access.
- `CloudKitKit` – Convenience helpers for working with CloudKit databases.
- `CommerceKit` – In‑app purchases, Apple Pay and order management.
- `DataModels` – Shared model types such as `UserProfile`, `Horoscope` and `Order`.
- `HoroscopeService` – Caching and fetching daily horoscopes.
- `NotificationKit` – Local and push notification scheduling.
- `SettingsKit` – User settings and preferences management.
- `SwissEphemeris` – Wrapper around the Swiss Ephemeris calculations.
- `UIComponents` – Reusable SwiftUI components used across the app.

Each folder contains its own `Package.swift`, `Sources/` and `Tests/` directories.

## Running Tests

Unit tests are provided per package. Run them with Swift Package Manager:

```bash
cd <PackageName>
swift test
```

Repeat for each package that you wish to test. Some packages depend on Apple frameworks and must be built on macOS with Xcode installed.
