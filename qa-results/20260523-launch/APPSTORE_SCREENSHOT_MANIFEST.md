# Astronova App Store Screenshot Manifest - 2026-05-23

## Device

- Simulator: iPhone 16 Pro Max
- Runtime: iOS 18.6
- Resolution: 1320 x 2868
- Backend for live Timeline/Matrix state: `http://127.0.0.1:18094`

## Canonical Upload Set

1. `app-store-assets/screenshots/01_hero.png` - Today dashboard
2. `app-store-assets/screenshots/02_valueprop.png` - Apple Maps globe
3. `app-store-assets/screenshots/03_painpoint.png` - Timeline live state
4. `app-store-assets/screenshots/04_benefit.png` - Matrix Loshu deep dive
5. `app-store-assets/screenshots/05_trust.png` - Journal Free Will decisions
6. `app-store-assets/screenshots/06_cta.png` - Pro paywall

## Evidence

- Raw captures: `app-store-assets/screenshots/2026-05-23-current/`
- 6.5-inch derivatives: `app-store-assets/screenshots/iphone65-current/`
- Archived stale set: `app-store-assets/screenshots/archive-20260523-stale/`
- Contact sheet: `qa-results/20260523-launch/appstore-screenshot-contact-sheet.png`
- 6.5-inch contact sheet: `qa-results/20260523-launch/appstore-screenshot-contact-sheet-iphone65.png`
- Dimension check: every canonical screenshot is `1320x2868`.
- Derivative dimension check: every `iphone65-current` screenshot is `1242x2688`.

## App Store Connect Read-Back

- App Store version: `1.0`, state `PREPARE_FOR_SUBMISSION`.
- `APP_IPHONE_67`: 6 screenshots, all `COMPLETE`.
- `APP_IPHONE_65`: 6 screenshots, all `COMPLETE`.
- Upload log: `qa-results/20260523-launch/asc-screenshot-upload.json`.
- Final screenshot read-back: `qa-results/20260523-launch/asc-screenshot-sets-after.json`.

## Live State Checks

- Timeline surface showed `LIVE`.
- Matrix surface showed `Live numerology report`.
- Map surface showed Apple Maps globe imagery and `astrocartography.appleMaps.badge`.
- Journal surface showed `journal.freeWillHero` and `journal.decisionLoop`.
- Paywall showed plan selection, restore, terms, privacy, and manage links.
