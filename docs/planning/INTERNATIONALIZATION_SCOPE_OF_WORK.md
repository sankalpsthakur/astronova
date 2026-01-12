# Internationalization & Localization Scope of Work
# Astronova - Global Launch Strategy

**Document Version:** 1.0
**Date:** January 13, 2026
**Current Status:** English-only (US) - Limited i18n infrastructure
**Goal:** Multi-language, multi-region support

---

## Executive Summary

Astronova currently operates as an English-only application with minimal internationalization infrastructure. To expand globally and reach the 7+ billion non-English speakers worldwide, we need comprehensive internationalization (i18n) and localization (l10n) implementation.

**Current State Analysis:**
- ✅ iOS: 47 localization strings across 17 files (partial)
- ❌ No `Localizable.strings` files
- ❌ No language project folders (`.lproj`)
- ❌ Backend: English-only API responses
- ⚠️ Pandit language preferences exist (temple feature) but unused
- ❌ No locale/timezone handling in backend
- ❌ All astrological content in English

**Market Opportunity:**
| Region | Market Size | Language | Priority |
|--------|-------------|----------|----------|
| India | 1.4B people | Hindi, Tamil, Telugu, Bengali, Marathi | **P0** (Primary market) |
| United States | 330M people | English, Spanish | **P1** (Current) |
| Latin America | 650M people | Spanish, Portuguese | **P2** |
| Europe | 450M people | German, French, Italian | **P2** |
| Middle East | 400M people | Arabic (RTL) | **P3** |
| Southeast Asia | 680M people | Indonesian, Thai, Vietnamese | **P3** |

**Estimated Effort:** 120-160 hours (3-4 weeks)
**Ongoing:** Translation management, content updates

---

## Phase 1: Foundation & Infrastructure (20-25 hours)

### 1.1 iOS Localization Infrastructure Setup
**Estimated Effort:** 8-10 hours

#### Current State:
```swift
// Current: Hardcoded strings in views
Text("Welcome to Astronova")
Button("Book Pooja") { }
.accessibilityLabel("Book a pooja ceremony")
```

**Problem:** All user-facing text hardcoded in English.

---

#### Implementation Steps:

**Step 1: Create Localizable.strings Files (2 hours)**

```bash
# Create English base localization
cd client/AstronovaApp
mkdir -p en.lproj
touch en.lproj/Localizable.strings

# Extract existing strings using genstrings
find . -name "*.swift" -print0 | xargs -0 genstrings -o en.lproj/

# Create additional language folders (Phase 2)
mkdir -p hi.lproj  # Hindi
mkdir -p es.lproj  # Spanish
mkdir -p ta.lproj  # Tamil
# ... (add more as needed)
```

**Step 2: Update Xcode Project Configuration (1 hour)**

1. Open `astronova.xcodeproj`
2. Select project → Info tab
3. Under "Localizations" click `+`
4. Add languages:
   - English (Base) ✓ (already exists)
   - Hindi (hi)
   - Spanish (es)
   - Tamil (ta)
   - Telugu (te)
   - Bengali (bn)
5. Select files to localize (Localizable.strings, storyboards)

**Step 3: Create String Constants File (2 hours)**

```swift
// client/AstronovaApp/Localization/LocalizedStrings.swift

import Foundation

/// Centralized localization strings for type-safe access
enum L10n {
    // MARK: - Tabs
    enum Tabs {
        static let discover = NSLocalizedString("tabs.discover", value: "Discover", comment: "Discover tab title")
        static let timeTravel = NSLocalizedString("tabs.timeTravel", value: "Time Travel", comment: "Time Travel tab title")
        static let temple = NSLocalizedString("tabs.temple", value: "Temple", comment: "Temple tab title")
        static let connect = NSLocalizedString("tabs.connect", value: "Connect", comment: "Connect tab title")
        static let self = NSLocalizedString("tabs.self", value: "Self", comment: "Self/profile tab title")
    }

    // MARK: - Common Actions
    enum Actions {
        static let save = NSLocalizedString("actions.save", value: "Save", comment: "Save button")
        static let cancel = NSLocalizedString("actions.cancel", value: "Cancel", comment: "Cancel button")
        static let delete = NSLocalizedString("actions.delete", value: "Delete", comment: "Delete button")
        static let edit = NSLocalizedString("actions.edit", value: "Edit", comment: "Edit button")
        static let done = NSLocalizedString("actions.done", value: "Done", comment: "Done button")
        static let next = NSLocalizedString("actions.next", value: "Next", comment: "Next button")
        static let back = NSLocalizedString("actions.back", value: "Back", comment: "Back button")
        static let close = NSLocalizedString("actions.close", value: "Close", comment: "Close button")
    }

    // MARK: - Home/Discover
    enum Home {
        static let cosmicWeatherTitle = NSLocalizedString("home.cosmicWeather.title", value: "Today's Cosmic Weather", comment: "Daily cosmic weather card title")
        static func cosmicWeatherDate(_ date: String) -> String {
            String(format: NSLocalizedString("home.cosmicWeather.date", value: "for %@", comment: "Cosmic weather date format"), date)
        }

        enum Domains {
            static let personal = NSLocalizedString("home.domains.personal", value: "Personal", comment: "Personal domain")
            static let love = NSLocalizedString("home.domains.love", value: "Love", comment: "Love domain")
            static let career = NSLocalizedString("home.domains.career", value: "Career", comment: "Career domain")
            static let wealth = NSLocalizedString("home.domains.wealth", value: "Wealth", comment: "Wealth domain")
            static let health = NSLocalizedString("home.domains.health", value: "Health", comment: "Health domain")
            static let family = NSLocalizedString("home.domains.family", value: "Family", comment: "Family domain")
            static let spiritual = NSLocalizedString("home.domains.spiritual", value: "Spiritual", comment: "Spiritual domain")
        }
    }

    // MARK: - Oracle (Chat)
    enum Oracle {
        static let title = NSLocalizedString("oracle.title", value: "Oracle", comment: "Oracle feature title")
        static let inputPlaceholder = NSLocalizedString("oracle.input.placeholder", value: "Ask Oracle about your cosmic journey...", comment: "Chat input placeholder")
        static let sendButton = NSLocalizedString("oracle.send", value: "Send", comment: "Send message button")
        static let typingIndicator = NSLocalizedString("oracle.typing", value: "Oracle is typing...", comment: "Typing indicator")

        enum Packages {
            static let title = NSLocalizedString("oracle.packages.title", value: "Chat Packages", comment: "Chat packages sheet title")
            static func messagesRemaining(_ count: Int) -> String {
                String(format: NSLocalizedString("oracle.packages.remaining", value: "%d messages remaining", comment: "Messages remaining format"), count)
            }
        }
    }

    // MARK: - Temple (Pooja Booking)
    enum Temple {
        static let title = NSLocalizedString("temple.title", value: "Temple", comment: "Temple feature title")
        static let selectPooja = NSLocalizedString("temple.selectPooja", value: "Select Pooja Type", comment: "Select pooja section header")
        static let selectPandit = NSLocalizedString("temple.selectPandit", value: "Select Pandit", comment: "Select pandit section header")

        enum Booking {
            static let confirmButton = NSLocalizedString("temple.booking.confirm", value: "Confirm Booking", comment: "Confirm booking button")
            static let dateLabel = NSLocalizedString("temple.booking.date", value: "Pooja Date", comment: "Date picker label")
            static let timeLabel = NSLocalizedString("temple.booking.time", value: "Time Slot", comment: "Time slot picker label")

            // Sankalp (Intent/Dedication)
            static let sankalpName = NSLocalizedString("temple.booking.sankalp.name", value: "Your Name", comment: "Sankalp name field")
            static let sankalpGotra = NSLocalizedString("temple.booking.sankalp.gotra", value: "Gotra (Optional)", comment: "Gotra field")
            static let sankalpNakshatra = NSLocalizedString("temple.booking.sankalp.nakshatra", value: "Nakshatra (Optional)", comment: "Nakshatra field")
            static let specialRequests = NSLocalizedString("temple.booking.specialRequests", value: "Special Requests", comment: "Special requests field")
        }

        enum Status {
            static let pending = NSLocalizedString("temple.status.pending", value: "Pending", comment: "Booking status: pending")
            static let confirmed = NSLocalizedString("temple.status.confirmed", value: "Confirmed", comment: "Booking status: confirmed")
            static let inProgress = NSLocalizedString("temple.status.inProgress", value: "In Progress", comment: "Booking status: in progress")
            static let completed = NSLocalizedString("temple.status.completed", value: "Completed", comment: "Booking status: completed")
            static let cancelled = NSLocalizedString("temple.status.cancelled", value: "Cancelled", comment: "Booking status: cancelled")
        }
    }

    // MARK: - Connect (Relationships)
    enum Connect {
        static let title = NSLocalizedString("connect.title", value: "Connect", comment: "Connect tab title")
        static let addRelationship = NSLocalizedString("connect.add", value: "Add Relationship", comment: "Add relationship button")
        static let emptyState = NSLocalizedString("connect.empty", value: "No relationships yet", comment: "Empty state message")

        enum Compatibility {
            static func score(_ score: Int) -> String {
                String(format: NSLocalizedString("connect.compatibility.score", value: "%d%% compatibility", comment: "Compatibility score format"), score)
            }

            enum Pulse {
                static let flowing = NSLocalizedString("connect.pulse.flowing", value: "Flowing", comment: "Relationship pulse: flowing")
                static let electric = NSLocalizedString("connect.pulse.electric", value: "Electric", comment: "Relationship pulse: electric")
                static let magnetic = NSLocalizedString("connect.pulse.magnetic", value: "Magnetic", comment: "Relationship pulse: magnetic")
                static let grounded = NSLocalizedString("connect.pulse.grounded", value: "Grounded", comment: "Relationship pulse: grounded")
                static let friction = NSLocalizedString("connect.pulse.friction", value: "Friction", comment: "Relationship pulse: friction")
            }
        }
    }

    // MARK: - Astrology Terms
    enum Astrology {
        // Zodiac Signs
        enum Signs {
            static let aries = NSLocalizedString("astrology.signs.aries", value: "Aries", comment: "Zodiac sign: Aries")
            static let taurus = NSLocalizedString("astrology.signs.taurus", value: "Taurus", comment: "Zodiac sign: Taurus")
            static let gemini = NSLocalizedString("astrology.signs.gemini", value: "Gemini", comment: "Zodiac sign: Gemini")
            static let cancer = NSLocalizedString("astrology.signs.cancer", value: "Cancer", comment: "Zodiac sign: Cancer")
            static let leo = NSLocalizedString("astrology.signs.leo", value: "Leo", comment: "Zodiac sign: Leo")
            static let virgo = NSLocalizedString("astrology.signs.virgo", value: "Virgo", comment: "Zodiac sign: Virgo")
            static let libra = NSLocalizedString("astrology.signs.libra", value: "Libra", comment: "Zodiac sign: Libra")
            static let scorpio = NSLocalizedString("astrology.signs.scorpio", value: "Scorpio", comment: "Zodiac sign: Scorpio")
            static let sagittarius = NSLocalizedString("astrology.signs.sagittarius", value: "Sagittarius", comment: "Zodiac sign: Sagittarius")
            static let capricorn = NSLocalizedString("astrology.signs.capricorn", value: "Capricorn", comment: "Zodiac sign: Capricorn")
            static let aquarius = NSLocalizedString("astrology.signs.aquarius", value: "Aquarius", comment: "Zodiac sign: Aquarius")
            static let pisces = NSLocalizedString("astrology.signs.pisces", value: "Pisces", comment: "Zodiac sign: Pisces")
        }

        // Planets
        enum Planets {
            static let sun = NSLocalizedString("astrology.planets.sun", value: "Sun", comment: "Planet: Sun")
            static let moon = NSLocalizedString("astrology.planets.moon", value: "Moon", comment: "Planet: Moon")
            static let mercury = NSLocalizedString("astrology.planets.mercury", value: "Mercury", comment: "Planet: Mercury")
            static let venus = NSLocalizedString("astrology.planets.venus", value: "Venus", comment: "Planet: Venus")
            static let mars = NSLocalizedString("astrology.planets.mars", value: "Mars", comment: "Planet: Mars")
            static let jupiter = NSLocalizedString("astrology.planets.jupiter", value: "Jupiter", comment: "Planet: Jupiter")
            static let saturn = NSLocalizedString("astrology.planets.saturn", value: "Saturn", comment: "Planet: Saturn")
            static let rahu = NSLocalizedString("astrology.planets.rahu", value: "Rahu", comment: "Planet: Rahu (North Node)")
            static let ketu = NSLocalizedString("astrology.planets.ketu", value: "Ketu", comment: "Planet: Ketu (South Node)")
        }

        // Dasha Periods
        enum Dasha {
            static let mahadasha = NSLocalizedString("astrology.dasha.mahadasha", value: "Mahadasha", comment: "Major period in Vimshottari Dasha")
            static let antardasha = NSLocalizedString("astrology.dasha.antardasha", value: "Antardasha", comment: "Sub-period in Vimshottari Dasha")
            static let pratyantardasha = NSLocalizedString("astrology.dasha.pratyantardasha", value: "Pratyantardasha", comment: "Sub-sub-period in Vimshottari Dasha")

            static func yearsFormat(_ years: Int) -> String {
                String(format: NSLocalizedString("astrology.dasha.years", value: "%d years", comment: "Dasha duration in years"), years)
            }
        }

        // Aspects
        enum Aspects {
            static let conjunction = NSLocalizedString("astrology.aspects.conjunction", value: "Conjunction", comment: "Aspect: Conjunction")
            static let sextile = NSLocalizedString("astrology.aspects.sextile", value: "Sextile", comment: "Aspect: Sextile")
            static let square = NSLocalizedString("astrology.aspects.square", value: "Square", comment: "Aspect: Square")
            static let trine = NSLocalizedString("astrology.aspects.trine", value: "Trine", comment: "Aspect: Trine")
            static let opposition = NSLocalizedString("astrology.aspects.opposition", value: "Opposition", comment: "Aspect: Opposition")
        }
    }

    // MARK: - Errors
    enum Errors {
        static let generic = NSLocalizedString("errors.generic", value: "Something went wrong. Please try again.", comment: "Generic error message")
        static let network = NSLocalizedString("errors.network", value: "Unable to connect. Check your internet connection.", comment: "Network error")
        static let unauthorized = NSLocalizedString("errors.unauthorized", value: "Please sign in to continue.", comment: "Unauthorized error")
        static let notFound = NSLocalizedString("errors.notFound", value: "The requested resource was not found.", comment: "Not found error")
    }

    // MARK: - Date & Time
    enum DateTime {
        static let today = NSLocalizedString("datetime.today", value: "Today", comment: "Today")
        static let tomorrow = NSLocalizedString("datetime.tomorrow", value: "Tomorrow", comment: "Tomorrow")
        static let yesterday = NSLocalizedString("datetime.yesterday", value: "Yesterday", comment: "Yesterday")

        // Relative time formatting handled by DateFormatter
    }
}
```

**Step 4: Update Views to Use Localized Strings (3-4 hours)**

```swift
// BEFORE (hardcoded):
Text("Welcome to Astronova")
Button("Book Pooja") { }

// AFTER (localized):
Text(L10n.Home.welcomeTitle)
Button(L10n.Temple.bookButton) { }

// For dynamic content:
Text(L10n.Oracle.Packages.messagesRemaining(10))
// Output: "10 messages remaining" (English)
// Output: "10 mensajes restantes" (Spanish)
// Output: "10 संदेश शेष हैं" (Hindi)
```

---

**Step 5: Pluralization Support (1 hour)**

```swift
// Create Localizable.stringsdict for plurals
// en.lproj/Localizable.stringsdict

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>oracle.packages.remaining</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@messages@</string>
        <key>messages</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No messages remaining</string>
            <key>one</key>
            <string>1 message remaining</string>
            <key>other</key>
            <string>%d messages remaining</string>
        </dict>
    </dict>

    <key>astrology.dasha.years</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@years@</string>
        <key>years</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>one</key>
            <string>1 year</string>
            <key>other</key>
            <string>%d years</string>
        </dict>
    </dict>
</dict>
</plist>
```

---

### 1.2 Backend API Localization Infrastructure
**Estimated Effort:** 6-8 hours

#### Current State:
- All API responses in English
- No locale detection
- No translation system
- Hardcoded astrological interpretations in English

---

#### Implementation Steps:

**Step 1: Install Flask-Babel (1 hour)**

```bash
# server/requirements.txt
Flask-Babel==4.0.0
```

```python
# server/app.py

from flask_babel import Babel, get_locale

def get_user_locale():
    """
    Determine user's locale from:
    1. Accept-Language header
    2. User profile preference (if authenticated)
    3. Default to English
    """
    # Check user preference from database (if authenticated)
    user_id = request.headers.get("X-User-Id")
    if user_id:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT preferred_language FROM users WHERE id = ?", (user_id,))
        row = cur.fetchone()
        conn.close()
        if row and row["preferred_language"]:
            return row["preferred_language"]

    # Fall back to Accept-Language header
    return request.accept_languages.best_match(['en', 'hi', 'es', 'ta', 'te', 'bn', 'ar'])

# Initialize Babel
babel = Babel(app, locale_selector=get_user_locale)
```

**Step 2: Create Translation Files (2 hours)**

```bash
# Extract translatable strings
cd server
pybabel extract -F babel.cfg -o messages.pot .

# Initialize language catalogs
pybabel init -i messages.pot -d translations -l hi  # Hindi
pybabel init -i messages.pot -d translations -l es  # Spanish
pybabel init -i messages.pot -d translations -l ta  # Tamil
pybabel init -i messages.pot -d translations -l te  # Telugu
pybabel init -i messages.pot -d translations -l bn  # Bengali
```

**Step 3: Wrap User-Facing Strings (3-4 hours)**

```python
# server/routes/horoscope.py

from flask_babel import gettext as _

@horoscope_bp.route("/", methods=["GET"])
def get_horoscope():
    sign = request.args.get("sign")
    horoscope_type = request.args.get("type", "daily")

    # Localized error messages
    if not sign:
        return jsonify({"error": _("Zodiac sign is required")}), 400

    # Generate horoscope (English content for now)
    horoscope = generate_horoscope(sign, horoscope_type, locale=get_locale())

    return jsonify({
        "sign": _(sign),  # Translate zodiac sign name
        "type": _(horoscope_type),
        "horoscope": horoscope,
        "date": datetime.utcnow().isoformat()
    })


# server/services/dasha_interpretation_service.py

from flask_babel import gettext as _, ngettext

def interpret_dasha_period(planet: str, start_date: str, end_date: str, locale: str = 'en') -> dict:
    """
    Generate localized interpretation for dasha period
    """
    # Planet name localization
    planet_name = _(f"planet.{planet.lower()}")

    # Calculate duration
    start = datetime.fromisoformat(start_date)
    end = datetime.fromisoformat(end_date)
    duration_years = (end - start).days // 365

    # Pluralized duration
    duration_text = ngettext(
        "%(num)d year",
        "%(num)d years",
        duration_years
    ) % {'num': duration_years}

    # Localized interpretation templates
    interpretations = {
        'Sun': _("dasha.sun.interpretation"),
        'Moon': _("dasha.moon.interpretation"),
        # ... (map to translation keys)
    }

    return {
        "planet": planet_name,
        "duration": duration_text,
        "interpretation": interpretations.get(planet, _("dasha.generic.interpretation"))
    }
```

**Step 4: Database Schema Update (1 hour)**

```sql
-- Add preferred_language column to users table
ALTER TABLE users ADD COLUMN preferred_language TEXT DEFAULT 'en';

-- Update migration: server/migrations/004_add_language_preference.py
import sqlite3

VERSION = 4
NAME = "add_language_preference"

def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("""
        ALTER TABLE users
        ADD COLUMN preferred_language TEXT DEFAULT 'en'
    """)
    conn.commit()

def down(conn: sqlite3.Connection) -> None:
    # SQLite doesn't support DROP COLUMN, would need table recreation
    pass
```

---

### 1.3 Date, Time, and Number Formatting
**Estimated Effort:** 4-5 hours

#### Locale-Aware Formatters:

**iOS Implementation:**

```swift
// client/AstronovaApp/Localization/LocaleFormatter.swift

import Foundation

class LocaleFormatter {
    static let shared = LocaleFormatter()

    // MARK: - Date Formatters

    /// Short date (e.g., "1/13/26" US, "13/1/26" UK, "13.1.26" DE)
    lazy var shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    /// Medium date (e.g., "Jan 13, 2026" US, "13 Jan 2026" UK)
    lazy var mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    /// Long date (e.g., "January 13, 2026")
    lazy var longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    /// Full date (e.g., "Monday, January 13, 2026")
    lazy var fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Time Formatters

    /// 12-hour time (e.g., "2:30 PM" US) or 24-hour (e.g., "14:30" most of world)
    lazy var time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Relative Date Formatter

    /// Relative date (e.g., "2 hours ago", "tomorrow")
    lazy var relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Number Formatters

    /// Decimal numbers with locale grouping (e.g., "1,234.56" US, "1.234,56" DE)
    lazy var decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter
    }()

    /// Percentage (e.g., "95%" US, "95 %" FR)
    lazy var percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // MARK: - Currency Formatters

    func currency(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        return formatter
    }

    /// Get currency code for current locale
    var localeCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Astrological Time Formatting

    /// Format birth time with locale conventions
    func birthTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "jjmm", options: 0, locale: Locale.current)
        return formatter.string(from: date)
    }

    /// Format timezone name
    func timezoneName(_ timezone: TimeZone) -> String {
        timezone.localizedName(for: .generic, locale: Locale.current) ?? timezone.identifier
    }
}

// Usage in Views:
struct HomeView: View {
    let date = Date()
    let compatibilityScore = 0.87

    var body: some View {
        VStack {
            // Date formatting
            Text(LocaleFormatter.shared.mediumDate.string(from: date))
            // Output: "Jan 13, 2026" (US)
            // Output: "13 janv. 2026" (France)
            // Output: "13 जन 2026" (India/Hindi)

            // Percentage formatting
            Text(LocaleFormatter.shared.percent.string(from: NSNumber(value: compatibilityScore)) ?? "")
            // Output: "87%" (US)
            // Output: "87 %" (France)
            // Output: "87%" (India)

            // Currency formatting
            let price = 1500.0  // INR
            Text(LocaleFormatter.shared.currency(for: "INR").string(from: NSNumber(value: price)) ?? "")
            // Output: "₹1,500.00" (India)
            // Output: "INR 1,500.00" (US)
        }
    }
}
```

**Backend Implementation:**

```python
# server/services/locale_formatter.py

from babel.dates import format_date, format_datetime, format_time
from babel.numbers import format_number, format_currency, format_percent
from datetime import datetime, timezone

class LocaleFormatter:
    def __init__(self, locale: str = 'en'):
        self.locale = locale

    def format_date(self, date: datetime, format_type: str = 'medium') -> str:
        """
        Format date according to locale
        format_type: 'short', 'medium', 'long', 'full'
        """
        return format_date(date, format=format_type, locale=self.locale)

    def format_time(self, time: datetime, format_type: str = 'short') -> str:
        """Format time according to locale (12hr vs 24hr)"""
        return format_time(time, format=format_type, locale=self.locale)

    def format_datetime(self, dt: datetime, format_type: str = 'medium') -> str:
        """Format datetime according to locale"""
        return format_datetime(dt, format=format_type, locale=self.locale)

    def format_number(self, number: float) -> str:
        """Format number with locale grouping (1,234.56 vs 1.234,56)"""
        return format_number(number, locale=self.locale)

    def format_currency(self, amount: float, currency: str = 'INR') -> str:
        """Format currency according to locale"""
        return format_currency(amount, currency, locale=self.locale)

    def format_percent(self, value: float) -> str:
        """Format percentage"""
        return format_percent(value, locale=self.locale)

# Usage in routes:
from flask_babel import get_locale

@temple_bp.route("/bookings/<booking_id>", methods=["GET"])
def get_booking(booking_id: str):
    formatter = LocaleFormatter(str(get_locale()))

    booking = get_booking_from_db(booking_id)

    return jsonify({
        "id": booking["id"],
        "pooja_name": _(booking["pooja_name"]),
        "scheduled_date": formatter.format_date(booking["scheduled_date"]),
        "scheduled_time": formatter.format_time(booking["scheduled_time"]),
        "amount_paid": formatter.format_currency(booking["amount_paid"], "INR"),
        "status": _(f"status.{booking['status']}")
    })
```

---

### 1.4 Cultural Adaptations
**Estimated Effort:** 2-3 hours

**Calendar Systems:**
```swift
// Support multiple calendar systems
// Gregorian (Western), Hindu (India), Islamic (Middle East)

extension Date {
    func formatted(for calendar: Calendar.Identifier, locale: Locale) -> String {
        var calendar = Calendar(identifier: calendar)
        calendar.locale = locale

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.locale = locale

        return formatter.string(from: self)
    }
}

// Usage:
let date = Date()
// Gregorian: "January 13, 2026"
date.formatted(for: .gregorian, locale: Locale(identifier: "en_US"))

// Hindu (Vikram Samvat): "माघ 24, 2082"
date.formatted(for: .indian, locale: Locale(identifier: "hi_IN"))

// Islamic (Hijri): "رجب 14, 1448"
date.formatted(for: .islamic, locale: Locale(identifier: "ar_SA"))
```

**First Day of Week:**
```swift
// Sunday (US) vs Monday (Europe, India)
let calendar = Calendar.current
let firstWeekday = calendar.firstWeekday
// 1 = Sunday (US)
// 2 = Monday (Europe, India)
```

---

## Phase 2: Content Translation (40-60 hours)

### 2.1 Translation Strategy & Priorities

**Tier 1 Languages (Launch Priority):**
| Language | Code | Speakers | Market | Rationale |
|----------|------|----------|--------|-----------|
| **English** | en | 1.5B | Global | Base language ✓ |
| **Hindi** | hi | 600M | India | Primary market, large astrology interest |
| **Spanish** | es | 550M | US + LatAm | Second-largest language group |
| **Tamil** | ta | 80M | India (South) | Strong astrology culture |
| **Telugu** | te | 95M | India (South) | High engagement potential |

**Tier 2 Languages (6-12 months):**
| Language | Code | Speakers | Market | Rationale |
|----------|------|----------|--------|-----------|
| **Bengali** | bn | 270M | India (East) | Large population |
| **Marathi** | mr | 85M | India (West) | Strong cultural ties |
| **Portuguese** | pt | 260M | Brazil | Latin America expansion |
| **German** | de | 100M | Europe | Premium market |
| **French** | fr | 280M | Europe + Africa | International reach |

**Tier 3 Languages (12+ months):**
- Arabic (ar) - 420M speakers, RTL support required
- Mandarin (zh) - 1.1B speakers, complex astrology terminology
- Japanese (ja) - 125M speakers, unique astrological system
- Indonesian (id) - 200M speakers, Southeast Asia

---

### 2.2 Translation Workflow

**Step 1: String Extraction (4 hours)**

```bash
# iOS: Extract all strings
cd client
find AstronovaApp -name "*.swift" | xargs genstrings -o en.lproj/

# Backend: Extract all strings
cd server
pybabel extract -F babel.cfg -o messages.pot .

# Result: ~2,000-3,000 strings to translate
```

**Step 2: Professional Translation (30-40 hours external)**

**Options:**

**A. Professional Translation Service (Recommended)**
- Services: Smartling, Transifex, Lokalise, POEditor
- Cost: ~$0.10-0.25 per word
- Timeline: 2-4 weeks for Tier 1 languages
- Quality: Native speakers + astrological expertise

**B. AI-Assisted Translation (Lower Cost)**
- Tools: DeepL API, Google Cloud Translation
- Cost: ~$20 per 1M characters
- Timeline: 1 week
- Quality: Requires human review for astrological terms

**C. Hybrid Approach (Best Value)**
1. AI translation for common strings (buttons, labels, errors)
2. Professional translation for:
   - Astrological interpretations
   - Pooja descriptions
   - Marketing content
   - Cultural content

**Translation Memory Setup:**
- Store translations in TMS (Translation Management System)
- Reuse translations across iOS + Backend
- Maintain glossary for consistency

---

### 2.3 Astrological Terminology Challenges

**Challenge 1: Sanskrit Terms**

Many astrological concepts have no direct translation:

| Sanskrit | English | Hindi | Spanish | Tamil |
|----------|---------|-------|---------|-------|
| Vimshottari Dasha | 120-year cycle | विंशोत्तरी दशा | Sistema de períodos | விம்சோத்தரி தசை |
| Mahadasha | Major period | महादशा | Período mayor | மகா தசை |
| Antardasha | Sub-period | अंतर्दशा | Subperíodo | அந்தர தசை |
| Nakshatra | Lunar mansion | नक्षत्र | Mansión lunar | நட்சத்திரம் |
| Gotra | Lineage | गोत्र | Linaje | கோத்திரம் |

**Solution: Transliteration + Explanation**
```swift
// Localizable.strings (Hindi)
"astrology.dasha.mahadasha" = "महादशा (Mahadasha)";
"astrology.dasha.mahadasha.description" = "मुख्य ग्रह की अवधि जो जीवन के प्रमुख चरणों को प्रभावित करती है";

// Localizable.strings (Spanish)
"astrology.dasha.mahadasha" = "Mahadasha (Período Mayor)";
"astrology.dasha.mahadasha.description" = "El período principal de un planeta que influye en las etapas importantes de la vida";
```

**Challenge 2: Zodiac Sign Names**

| English | Hindi (Direct) | Hindi (Vedic) | Tamil | Spanish |
|---------|----------------|---------------|-------|---------|
| Aries | मेष (Mesh) | मेष राशि | மேஷம் | Aries |
| Taurus | वृषभ (Vrishabh) | वृषभ राशि | ரிஷபம் | Tauro |
| Gemini | मिथुन (Mithun) | मिथुन राशि | மிதுனம் | Géminis |

**Solution: Dual naming system**
```json
// API Response
{
  "sign": {
    "western": "Aries",
    "vedic": "Mesha",
    "localized": "मेष राशि"  // Based on locale
  }
}
```

**Challenge 3: Planet Names**

| Planet | Hindi | Tamil | Spanish | Arabic |
|--------|-------|-------|---------|--------|
| Sun | सूर्य (Surya) | சூரியன் | Sol | الشمس |
| Moon | चंद्र (Chandra) | சந்திரன் | Luna | القمر |
| Mars | मंगल (Mangal) | செவ்வாய் | Marte | المريخ |
| Mercury | बुध (Budh) | புதன் | Mercurio | عطارد |
| Jupiter | गुरु/बृहस्पति (Guru/Brihaspati) | குரு | Júpiter | المشتري |
| Saturn | शनि (Shani) | சனி | Saturno | زحل |
| Rahu | राहु | ராகு | Rahu (node lunar norte) | راهو |
| Ketu | केतु | கேது | Ketu (node lunar sur) | كيتو |

---

### 2.4 Content Translation Priority

**High Priority (Must translate):**
- [ ] UI labels, buttons, navigation (500 strings)
- [ ] Error messages (50 strings)
- [ ] Onboarding flow (100 strings)
- [ ] Tab names and screen titles (30 strings)
- [ ] Form labels and placeholders (150 strings)
- [ ] Pooja names and descriptions (50 strings)
- [ ] Zodiac signs and planets (40 strings)

**Medium Priority:**
- [ ] Daily horoscope templates (365 strings)
- [ ] Domain insights (500+ strings)
- [ ] Dasha interpretations (200 strings)
- [ ] Compatibility descriptions (100 strings)

**Low Priority (Can defer):**
- [ ] Legal text (Privacy Policy, Terms) - keep English + local language link
- [ ] FAQ content
- [ ] Marketing copy
- [ ] Blog content (if applicable)

---

## Phase 3: Right-to-Left (RTL) Language Support (15-20 hours)

### 3.1 RTL Languages

**Arabic (ar):** 420M speakers - Middle East, North Africa
**Hebrew (he):** 9M speakers - Israel
**Urdu (ur):** 230M speakers - Pakistan, India
**Persian (fa):** 110M speakers - Iran

---

### 3.2 iOS RTL Implementation

**Step 1: Enable RTL Support (1 hour)**

```swift
// SwiftUI automatically handles RTL when locale is set
// But verify layout doesn't break

// Test RTL in simulator:
// Edit Scheme → Run → Options → App Language → Arabic
// OR
// Settings → General → Language & Region → Arabic → Set as Primary
```

**Step 2: Fix RTL Layout Issues (8-10 hours)**

**Common Issues:**

**Issue 1: Leading/Trailing vs Left/Right**
```swift
// WRONG (breaks in RTL):
HStack {
    Image(systemName: "star")
        .padding(.left, 8)  // Always left, even in RTL
    Text("Favorite")
}

// CORRECT (mirrors in RTL):
HStack {
    Image(systemName: "star")
        .padding(.leading, 8)  // Left in LTR, Right in RTL
    Text("Favorite")
}
```

**Issue 2: Icon Direction**
```swift
// Some icons should NOT mirror
Image(systemName: "chevron.right")
    .environment(\.layoutDirection, .leftToRight)  // Force LTR

// Most icons should mirror automatically
Image(systemName: "arrow.forward")
// Becomes arrow.backward in RTL automatically
```

**Issue 3: Text Alignment**
```swift
// Let text align naturally with locale
Text("مرحبا بكم في أسترونوفا")
    .multilineTextAlignment(.leading)  // Right-aligned in RTL
// NOT .leading = left always
```

**Step 3: Test All Views in RTL (4-5 hours)**

**Testing Checklist:**
- [ ] Navigation flows (back buttons flip)
- [ ] Tab bar (icons flip left to right)
- [ ] Lists and ScrollViews (scroll direction)
- [ ] Forms (labels on correct side)
- [ ] Charts (time flows right to left)
- [ ] Carousels and paging (direction reverses)

---

### 3.3 Backend RTL Considerations

```python
# server/services/pdf/report_renderer.py

from bidi.algorithm import get_display  # Python BiDi library
from arabic_reshaper import reshape  # For Arabic text rendering

def render_pdf_report(user_id: str, report_type: str, locale: str = 'en'):
    # Check if RTL language
    rtl_languages = ['ar', 'he', 'ur', 'fa']
    is_rtl = locale in rtl_languages

    if is_rtl:
        # Reshape Arabic text for proper rendering
        text = reshape("مرحبا بكم")
        # Apply BiDi algorithm
        display_text = get_display(text)

        # Set PDF layout direction
        pdf_canvas = Canvas(filename)
        if is_rtl:
            # Right-to-left layout
            pdf_canvas.setRTL(True)

    # Generate PDF with correct text direction
    # ...
```

---

## Phase 4: Regional Variations & Market-Specific Features (10-15 hours)

### 4.1 Currency Handling

**Implementation:**

```swift
// client/AstronovaApp/Localization/CurrencyManager.swift

enum CurrencyManager {
    /// Get currency code for user's region
    static func localeCurrency() -> String {
        // Priority:
        // 1. User's saved preference
        // 2. Device locale
        // 3. Default to USD

        if let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") {
            return savedCurrency
        }

        return Locale.current.currency?.identifier ?? "USD"
    }

    /// Currency by market
    static let marketCurrencies: [String: String] = [
        "IN": "INR",  // India - Rupees
        "US": "USD",  // United States - Dollars
        "GB": "GBP",  // United Kingdom - Pounds
        "EU": "EUR",  // Europe - Euros
        "BR": "BRL",  // Brazil - Reals
        "MX": "MXN",  // Mexico - Pesos
        "AE": "AED",  // UAE - Dirhams
    ]

    /// Format price based on locale
    static func formatPrice(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        return formatter.string(from: amount as NSNumber) ?? "\(currencyCode) \(amount)"
    }
}

// Usage:
struct PoojaCard: View {
    let pooja: Pooja

    var body: some View {
        VStack {
            Text(pooja.name)
            Text(CurrencyManager.formatPrice(pooja.basePrice, currencyCode: CurrencyManager.localeCurrency()))
            // Output: "₹1,500" (India)
            // Output: "$20" (US - converted price)
            // Output: "€18" (Europe - converted price)
        }
    }
}
```

**Backend: Dynamic Pricing by Region**

```python
# server/services/pricing_service.py

EXCHANGE_RATES = {
    'INR': 1.0,      # Base currency
    'USD': 0.012,    # 1 INR = 0.012 USD
    'EUR': 0.011,    # 1 INR = 0.011 EUR
    'GBP': 0.0095,   # 1 INR = 0.0095 GBP
    'BRL': 0.060,    # 1 INR = 0.060 BRL
    'AED': 0.044,    # 1 INR = 0.044 AED
}

def get_price_for_region(base_price_inr: float, target_currency: str) -> float:
    """Convert base price (INR) to target currency"""
    rate = EXCHANGE_RATES.get(target_currency, EXCHANGE_RATES['USD'])
    return round(base_price_inr * rate, 2)

# API endpoint
@temple_bp.route("/poojas", methods=["GET"])
def list_poojas():
    currency = request.args.get("currency", "INR")

    poojas = get_poojas_from_db()

    for pooja in poojas:
        # Convert price to requested currency
        pooja["price"] = get_price_for_region(pooja["base_price_inr"], currency)
        pooja["currency"] = currency

    return jsonify({"poojas": poojas})
```

---

### 4.2 Market-Specific Content

**India-Specific Features:**
- Vedic astrology focus (Vimshottari Dasha, Nakshatras)
- Pooja booking (already implemented)
- Festival calendar (Diwali, Holi, etc.)
- Regional language support (Hindi, Tamil, Telugu, Bengali, Marathi)
- Payment: UPI, Paytm, PhonePe

**US/Western Market:**
- Western astrology emphasis (Sun sign horoscopes)
- Simplified terminology (avoid Sanskrit)
- Psychological framing (less predictive, more guidance)
- Payment: Apple Pay, Credit Cards

**Middle East:**
- Islamic calendar integration
- Prayer times compatibility
- RTL language support (Arabic)
- Cultural sensitivity (family values, modesty)

**Latin America:**
- Spanish + Portuguese
- Strong astrology interest (high engagement)
- Local payment methods (Mercado Pago, PIX)

---

### 4.3 Regional Content Configuration

```swift
// client/AstronovaApp/Config/RegionalConfig.swift

enum RegionalConfig {
    enum Region: String {
        case india = "IN"
        case unitedStates = "US"
        case europe = "EU"
        case latinAmerica = "LATAM"
        case middleEast = "ME"

        static var current: Region {
            let countryCode = Locale.current.region?.identifier ?? "US"
            switch countryCode {
            case "IN": return .india
            case "US", "CA": return .unitedStates
            case "DE", "FR", "GB", "IT", "ES": return .europe
            case "MX", "BR", "AR", "CO": return .latinAmerica
            case "AE", "SA", "QA": return .middleEast
            default: return .unitedStates
            }
        }
    }

    /// Astrology system preference by region
    static func preferredAstrologySystem(for region: Region) -> AstrologySystem {
        switch region {
        case .india: return .vedic
        case .unitedStates, .europe, .latinAmerica: return .western
        case .middleEast: return .western  // Or Islamic astrology
        }
    }

    /// Feature availability by region
    static func isFeatureAvailable(_ feature: Feature, in region: Region) -> Bool {
        switch feature {
        case .poojaBooking:
            return region == .india || region == .middleEast
        case .vedicDasha:
            return region == .india
        case .sunSignHoroscopes:
            return true  // Available everywhere
        }
    }
}
```

---

## Phase 5: Testing & Quality Assurance (15-20 hours)

### 5.1 Localization Testing

**Manual Testing Checklist (per language):**

**Visual Verification:**
- [ ] All text displays correctly (no placeholder strings like "astrology.signs.aries")
- [ ] No text truncation (German words are longer)
- [ ] No UI overflow (Arabic text can be 30% longer)
- [ ] Buttons remain readable at all text sizes
- [ ] Icons and images culturally appropriate

**Functional Testing:**
- [ ] Date/time pickers work correctly
- [ ] Number formatting accurate (decimal separators)
- [ ] Currency displays correctly
- [ ] Pluralization works (1 message vs 2 messages)
- [ ] Gender agreement (for languages like Spanish, French)

**RTL Testing (Arabic, Hebrew):**
- [ ] Layout mirrors correctly
- [ ] Navigation flows right-to-left
- [ ] Icons flip appropriately
- [ ] Text alignment natural
- [ ] Scroll direction correct

---

### 5.2 Pseudolocalization

**Technique:** Generate fake translations to catch i18n bugs early

```swift
// Example: Pseudolocalize English
// "Welcome to Astronova" → "[!!! Ŵëļçömë ţö Ȧşţŕöñöṿȧ !!!]"

// Benefits:
// 1. Identifies hardcoded strings (won't be pseudolocalized)
// 2. Reveals text expansion issues (30% longer)
// 3. Tests character encoding (accented characters)
// 4. No translation cost

// Tools:
// - Xcode: Add "Pseudolanguage" in scheme settings
// - Custom script to generate pseudo translations
```

---

### 5.3 Automated Testing

```swift
// client/AstronovaAppTests/LocalizationTests.swift

import XCTest
@testable import AstronovaApp

class LocalizationTests: XCTestCase {

    func testAllStringsAreLocalized() {
        let supportedLanguages = ["en", "hi", "es", "ta", "te"]

        for language in supportedLanguages {
            let bundle = Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj")!)
            XCTAssertNotNil(bundle, "Missing localization bundle for \(language)")

            // Verify key strings exist
            let tabDiscover = NSLocalizedString("tabs.discover", bundle: bundle!, value: "", comment: "")
            XCTAssertFalse(tabDiscover.isEmpty, "Missing translation for tabs.discover in \(language)")
            XCTAssertNotEqual(tabDiscover, "tabs.discover", "Untranslated string in \(language)")
        }
    }

    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 1705161600)  // Jan 13, 2024

        // US English
        let usLocale = Locale(identifier: "en_US")
        let usFormatter = DateFormatter()
        usFormatter.dateStyle = .medium
        usFormatter.locale = usLocale
        XCTAssertEqual(usFormatter.string(from: date), "Jan 13, 2024")

        // India Hindi
        let inLocale = Locale(identifier: "hi_IN")
        let inFormatter = DateFormatter()
        inFormatter.dateStyle = .medium
        inFormatter.locale = inLocale
        XCTAssertTrue(inFormatter.string(from: date).contains("13"))  // Date should be present
    }

    func testCurrencyFormatting() {
        let price: Decimal = 1500

        // India - Rupees
        let inrFormatted = CurrencyManager.formatPrice(price, currencyCode: "INR")
        XCTAssertTrue(inrFormatted.contains("₹") || inrFormatted.contains("INR"))

        // US - Dollars
        let usdFormatted = CurrencyManager.formatPrice(price, currencyCode: "USD")
        XCTAssertTrue(usdFormatted.contains("$") || usdFormatted.contains("USD"))
    }

    func testRTLLayout() {
        // Simulate RTL locale
        let arabicLocale = Locale(identifier: "ar")

        // Verify layout direction
        XCTAssertEqual(arabicLocale.language.characterDirection, .rightToLeft)
    }
}
```

---

### 5.4 In-Market Testing (Beta)

**Approach:**
1. **Recruit native speakers** (5-10 per language)
2. **TestFlight beta** with localized builds
3. **Feedback collection:**
   - Translation accuracy
   - Cultural appropriateness
   - Missing translations
   - UI/UX issues

**Focus Areas:**
- Astrological terminology clarity
- Date/time format comfort
- Payment flow (local methods)
- Customer support language preference

---

## Phase 6: Ongoing Maintenance & Updates (Ongoing)

### 6.1 Translation Management System (TMS)

**Recommended Tools:**

**Option A: Lokalise (Preferred)**
- iOS + Backend support
- Translation memory
- Machine translation integration
- GitHub integration (auto-sync)
- Collaboration features
- Cost: ~$120/month

**Option B: Transifex**
- Popular open-source option
- Good documentation
- Cost: ~$99/month

**Option C: POEditor**
- Affordable
- Simple interface
- Cost: ~$50/month

**Setup (Lokalise Example):**
1. Create Lokalise project
2. Upload `Localizable.strings` (iOS) and `messages.pot` (Backend)
3. Assign translators
4. Configure GitHub integration for auto-updates
5. Set up continuous localization pipeline

---

### 6.2 Continuous Localization Workflow

```yaml
# .github/workflows/localization.yml

name: Localization Sync

on:
  push:
    branches: [main]
    paths:
      - 'client/AstronovaApp/**/*.swift'
      - 'server/**/*.py'

jobs:
  extract-and-upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Extract iOS strings
        run: |
          cd client
          find AstronovaApp -name "*.swift" | xargs genstrings -o en.lproj/

      - name: Extract Backend strings
        run: |
          cd server
          pip install babel
          pybabel extract -F babel.cfg -o messages.pot .

      - name: Upload to Lokalise
        uses: lokalise/lokalise-github-actions@v1
        with:
          api-token: ${{ secrets.LOKALISE_API_TOKEN }}
          project-id: ${{ secrets.LOKALISE_PROJECT_ID }}
          file: 'en.lproj/Localizable.strings'

  download-translations:
    runs-on: ubuntu-latest
    needs: extract-and-upload
    steps:
      - name: Download from Lokalise
        uses: lokalise/lokalise-github-actions@v1
        with:
          api-token: ${{ secrets.LOKALISE_API_TOKEN }}
          project-id: ${{ secrets.LOKALISE_PROJECT_ID }}
          action: 'download'

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v4
        with:
          commit-message: 'Update translations from Lokalise'
          title: 'Localization Updates'
          body: 'Auto-generated translation updates'
```

---

### 6.3 New Feature Localization Checklist

**Before Merging:**
- [ ] All new strings use `NSLocalizedString` (iOS) or `_()` (Backend)
- [ ] Strings have context comments for translators
- [ ] Date/time/number formatters used (no hardcoded formats)
- [ ] Currency handling for payments
- [ ] Tested in at least 2 locales
- [ ] No hardcoded text in images (use separate assets per locale)

**After Merging:**
- [ ] Upload new strings to TMS
- [ ] Notify translators
- [ ] Review translations when complete
- [ ] Test in each language before release

---

## Implementation Timeline

### Week 1-2: Foundation (Phase 1)
- **Days 1-3:** iOS localization infrastructure
  - Create .lproj folders
  - Set up LocalizedStrings.swift
  - Configure Xcode project
- **Days 4-5:** Backend i18n setup
  - Install Flask-Babel
  - Create translation catalogs
  - Wrap user-facing strings
- **Days 6-8:** Date/time/currency formatting
  - Implement LocaleFormatter
  - Test with multiple locales
- **Days 9-10:** Cultural adaptations
  - Calendar systems
  - Regional preferences

### Week 3-4: Content Translation (Phase 2)
- **Days 1-3:** String extraction
  - Generate all Localizable.strings
  - Extract backend messages.pot
  - Audit string count (~2,500 strings)
- **Days 4-14:** Professional translation (external)
  - Tier 1 languages: Hindi, Spanish, Tamil, Telugu
  - Astrological terminology glossary
  - Review and QA
- **Days 15-16:** Integration
  - Import translations
  - Build localized app versions
  - Smoke testing

### Week 5: RTL + Regional Features (Phases 3-4)
- **Days 1-3:** RTL implementation
  - Fix layout issues
  - Test Arabic/Hebrew
- **Days 4-5:** Regional variations
  - Currency handling
  - Market-specific content
  - Feature gates

### Week 6: Testing & Launch (Phases 5-6)
- **Days 1-3:** QA testing
  - Manual testing per language
  - Automated tests
  - Pseudolocalization
- **Days 4-5:** Beta testing
  - TestFlight with native speakers
  - Feedback collection
  - Bug fixes
- **Day 6:** TMS setup
  - Configure Lokalise/Transifex
  - Set up CI/CD pipeline
- **Day 7:** Launch
  - App Store submissions (localized)
  - Monitoring

---

## Estimated Costs

### Translation Services
| Item | Tier 1 (5 languages) | Tier 2 (5 languages) | Notes |
|------|---------------------|---------------------|-------|
| **UI Strings** (2,500 words) | $600-1,500 | $600-1,500 | Professional translation |
| **Content** (5,000 words) | $1,200-3,000 | $1,200-3,000 | Horoscopes, interpretations |
| **Specialized** (1,000 words) | $400-1,000 | $400-1,000 | Astrological terms, pooja descriptions |
| **Review & QA** | $300-500 | $300-500 | Native speaker review |
| **Total Translation** | **$2,500-6,000** | **$2,500-6,000** | Per language tier |

### Tools & Services
| Tool | Cost | Purpose |
|------|------|---------|
| Lokalise/Transifex | $120/month | Translation management |
| DeepL API | $25/month | AI-assisted translation |
| Professional proofreading | $500-1,000 | One-time per language |
| Beta testing incentives | $500 | TestFlight testers |
| **Total Ongoing** | **~$200/month** | After initial setup |

### Internal Effort
| Phase | Hours | Rate ($150/hr) | Cost |
|-------|-------|----------------|------|
| Phase 1: Foundation | 20-25 | $150 | $3,000-3,750 |
| Phase 2: Integration | 10-15 | $150 | $1,500-2,250 |
| Phase 3: RTL | 15-20 | $150 | $2,250-3,000 |
| Phase 4: Regional | 10-15 | $150 | $1,500-2,250 |
| Phase 5: Testing | 15-20 | $150 | $2,250-3,000 |
| Phase 6: Maintenance setup | 5-10 | $150 | $750-1,500 |
| **Total Internal** | **75-105 hrs** | | **$11,250-15,750** |

### **Grand Total (Tier 1 Launch):**
- **Translation:** $2,500-6,000 per language tier
- **Internal Development:** $11,250-15,750
- **Tools (first year):** $2,400
- **Total:** **$16,150-24,150** (one-time)
- **Ongoing:** ~$200/month + new content translation

---

## Success Metrics

### Quantitative
- [ ] 100% of UI strings localized in Tier 1 languages
- [ ] 0 placeholder strings visible to users
- [ ] Date/time formatting works in all supported locales
- [ ] Currency conversion accurate (±2%)
- [ ] RTL layouts render correctly (0 critical bugs)
- [ ] App Store presence in 5+ countries
- [ ] Load time impact < 5% with localized content

### Qualitative
- [ ] Native speakers approve translations (4.5+ star rating in reviews mentioning language)
- [ ] Astrological terminology accurate
- [ ] Cultural sensitivity maintained
- [ ] User engagement increases in localized markets

### Market Penetration
- [ ] India: 40% of user base (from current 10%)
- [ ] Latin America: 15% of user base (from 5%)
- [ ] Downloads increase 200-300% in localized regions
- [ ] Subscription conversion rate parity across languages

---

## Risk Mitigation

### Technical Risks
| Risk | Mitigation |
|------|-----------|
| Text expansion breaks layouts | Pseudolocalization testing |
| RTL bugs | Early testing with Arabic beta |
| Performance impact | Lazy-load locale bundles |
| Translation quality | Professional + native review |

### Business Risks
| Risk | Mitigation |
|------|-----------|
| Low ROI in some markets | Phased rollout (Tier 1 first) |
| Customer support in multiple languages | AI chatbot + escalation to English |
| Payment methods vary | Stripe multi-currency + local gateways |

---

## Appendix A: Language Resource Files Structure

```
client/AstronovaApp/
├── en.lproj/
│   ├── Localizable.strings
│   └── Localizable.stringsdict
├── hi.lproj/
│   ├── Localizable.strings
│   └── Localizable.stringsdict
├── es.lproj/
│   ├── Localizable.strings
│   └── Localizable.stringsdict
├── ta.lproj/
│   └── Localizable.strings
└── te.lproj/
    └── Localizable.strings

server/
├── translations/
│   ├── en/
│   │   └── LC_MESSAGES/
│   │       ├── messages.po
│   │       └── messages.mo
│   ├── hi/
│   │   └── LC_MESSAGES/
│   │       ├── messages.po
│   │       └── messages.mo
│   └── es/
│       └── LC_MESSAGES/
│           ├── messages.po
│           └── messages.mo
└── babel.cfg
```

---

## Appendix B: Sample Translation File

```
// en.lproj/Localizable.strings

/* Tab titles */
"tabs.discover" = "Discover";
"tabs.timeTravel" = "Time Travel";
"tabs.temple" = "Temple";
"tabs.connect" = "Connect";
"tabs.self" = "Self";

/* Home - Cosmic Weather */
"home.cosmicWeather.title" = "Today's Cosmic Weather";
"home.cosmicWeather.date" = "for %@";

/* Home - Domains */
"home.domains.personal" = "Personal";
"home.domains.love" = "Love";
"home.domains.career" = "Career";
"home.domains.wealth" = "Wealth";
"home.domains.health" = "Health";
"home.domains.family" = "Family";
"home.domains.spiritual" = "Spiritual";

/* Oracle */
"oracle.title" = "Oracle";
"oracle.input.placeholder" = "Ask Oracle about your cosmic journey...";
"oracle.send" = "Send";
"oracle.typing" = "Oracle is typing...";
"oracle.packages.remaining" = "%d messages remaining";

/* Temple - Booking */
"temple.title" = "Temple";
"temple.selectPooja" = "Select Pooja Type";
"temple.selectPandit" = "Select Pandit";
"temple.booking.confirm" = "Confirm Booking";
"temple.booking.date" = "Pooja Date";
"temple.booking.time" = "Time Slot";

/* Temple - Status */
"temple.status.pending" = "Pending";
"temple.status.confirmed" = "Confirmed";
"temple.status.inProgress" = "In Progress";
"temple.status.completed" = "Completed";
"temple.status.cancelled" = "Cancelled";

/* Astrology - Signs */
"astrology.signs.aries" = "Aries";
"astrology.signs.taurus" = "Taurus";
// ... (all 12 signs)

/* Astrology - Planets */
"astrology.planets.sun" = "Sun";
"astrology.planets.moon" = "Moon";
"astrology.planets.rahu" = "Rahu";
"astrology.planets.ketu" = "Ketu";
// ... (all planets)

/* Errors */
"errors.generic" = "Something went wrong. Please try again.";
"errors.network" = "Unable to connect. Check your internet connection.";
"errors.unauthorized" = "Please sign in to continue.";
```

---

**Document End**

For questions or implementation support:
- i18n Best Practices: https://developer.apple.com/internationalization/
- Flask-Babel Docs: https://python-babel.github.io/flask-babel/
- Unicode CLDR: https://cldr.unicode.org/
