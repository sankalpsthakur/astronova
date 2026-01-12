# Localization (i18n/l10n) Setup

This project uses a shared, key-driven localization approach for iOS and Flask-Babel for backend API responses.

## iOS (SwiftUI)

### Structure
- `client/AstronovaApp/Localization/LocalizedStrings.swift`: Type-safe accessors (`L10n.*`).
- `client/AstronovaApp/Localization/LocaleFormatter.swift`: Locale-aware date/number formatting.
- `client/AstronovaApp/Localization/CurrencyManager.swift`: Currency formatting helpers.
- `client/AstronovaApp/*.lproj/Localizable.strings`: Language catalogs.
- `client/AstronovaApp/*.lproj/Localizable.stringsdict`: Plurals.

### Adding a new string
1. Add a key + default value in `client/AstronovaApp/Localization/LocalizedStrings.swift`.
2. Add the same key to `client/AstronovaApp/en.lproj/Localizable.strings`.
3. Propagate to other locales (`hi`, `es`, `ta`, `te`, `bn`) until translations are available.

### Plurals
Use `Localizable.stringsdict` (example: `oracle.packages.remaining`, `astrology.dasha.years`).

### Notes on extraction
`genstrings` only detects direct `NSLocalizedString` usage. Because we wrap access through `L10n.tr(...)`, keep `Localizable.strings` up to date manually (or add a custom key exporter later).

## Backend (Flask)

### Structure
- `server/app.py`: Flask-Babel setup and locale selection.
- `server/messages.pot`: Extracted catalog template.
- `server/translations/<lang>/LC_MESSAGES/messages.po`: Locale catalogs.
- `server/services/locale_formatter.py`: Locale-aware formatting utilities.

### Locale selection
`get_user_locale()` prioritizes user preference, then `Accept-Language`, then defaults to English.

## Extraction workflow

### iOS strings
```
./tools/localization/extract_ios_strings.sh
```
This regenerates `client/AstronovaApp/en.lproj/Localizable.strings` from direct `NSLocalizedString` calls.

### Backend strings
```
./tools/localization/extract_backend_strings.sh
./tools/localization/update_backend_locales.sh
```
The extraction script ignores hidden directories and local virtual environments.

## Recommended workflow for new features
1. Add new `L10n` keys and update `Localizable.strings`.
2. Wrap backend user-facing strings with `gettext`/`ngettext`.
3. Run extraction scripts.
4. Send catalogs to translators or update translated `.po` files.
5. Verify in iOS with pseudolocalization and in API responses by changing locale headers.
