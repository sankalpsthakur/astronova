# Internationalization Implementation Backlog

> Tracks execution tasks for `INTERNATIONALIZATION_SCOPE_OF_WORK.md`.

## Phase 0: Audit & Inventory
- [ ] Inventory hardcoded UI strings in `client/AstronovaApp`.
- [ ] Inventory API response strings and user-facing errors in `server/routes`.
- [ ] Identify locale/currency usage across client + server.

## Phase 1: Backend i18n Scaffolding
- [x] Add Flask-Babel dependency + extraction config (`server/requirements.txt`, `server/babel.cfg`).
- [x] Add locale selector + supported locales in `server/app.py`.
- [x] Add `preferred_language` migration + DB helper (`server/migrations/005_add_user_preferred_language.py`, `server/db.py`).
- [x] Add locale formatter utility (`server/services/locale_formatter.py`).
- [x] Wrap horoscope error strings with gettext (`server/routes/horoscope.py`).
- [x] Wrap auth/temple/chat user-facing strings with gettext (`server/routes/auth.py`, `server/routes/temple.py`, `server/routes/chat.py`).

## Phase 2: iOS Localization Scaffolding
- [x] Add localization helpers (`client/AstronovaApp/Localization/LocalizedStrings.swift`, `LocaleFormatter.swift`, `CurrencyManager.swift`).
- [x] Create `en.lproj/Localizable.strings` + `Localizable.stringsdict` and register in Xcode project.
- [x] Replace hardcoded strings in P0 screens (tabs, onboarding, temple, oracle, errors).

## Phase 3: Translation Workflow
- [x] Document i18n setup + extraction workflow (`docs/localization.md`).
- [x] Add extraction scripts (genstrings + pybabel) and baseline catalogs.
- [x] Run extraction scripts and refresh backend catalogs (`server/messages.pot`, `server/translations/*`).
- [ ] Establish glossary/terminology rules for Sanskrit/Vedic terms.
- [x] Seed Tier-1 locales (hi/es/ta/te/bn).

## Phase 4: RTL + Regionalization
- [ ] Audit and fix LTR assumptions (leading/trailing, icon mirroring).
- [ ] Add region feature gating + currency defaults.
- [ ] Validate alternate calendar options.

## Phase 5: Testing & QA
- [ ] Add automated localization coverage tests (iOS + backend).
- [ ] Add pseudolocalization support and smoke checks.
- [ ] Run RTL + locale manual QA checklist.

## Phase 6: Release Readiness
- [ ] Localize App Store metadata and screenshots.
- [ ] Add localization sync pipeline (TMS/CI).
- [ ] Define post-launch monitoring metrics by locale.
