import SwiftUI

// MARK: - Essence Bar
// Compact Vedic identity display: Nakshatra + Lagna
// NOT Western Big 3 - this is uniquely Vedic

struct EssenceBar: View {
    let moonNakshatra: String?
    let lagna: String?
    let nakshatraLord: String?
    /// Audit A0d: when birth time is unknown, the Lagna (ascendant) is computed
    /// against a 12:00 noon stand-in and is therefore approximate. Show this
    /// inline so users know the reading isn't a precise calculation.
    var lagnaIsApproximate: Bool = false

    var body: some View {
        HStack(spacing: Cosmic.Spacing.lg) {
            // Moon Nakshatra (primary in Vedic)
            EssenceChip(
                symbol: "☽",
                label: moonNakshatra ?? "—",
                sublabel: nakshatraLord != nil ? "\(nakshatraLord!) ruled" : nil,
                color: .planetMoon
            )

            // Separator
            Circle()
                .fill(Color.cosmicTextTertiary.opacity(0.3))
                .frame(width: 4, height: 4)

            // Lagna (Ascendant)
            EssenceChip(
                symbol: "⬆",
                label: lagna != nil ? "\(lagna!) Lagna" : "—",
                sublabel: lagna != nil && lagnaIsApproximate ? "(approximate)" : nil,
                color: .cosmicGold
            )
        }
        .padding(.horizontal, Cosmic.Spacing.md)
        .padding(.vertical, Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.pill, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.pill, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Essence Chip

private struct EssenceChip: View {
    let symbol: String
    let label: String
    let sublabel: String?
    let color: Color

    var body: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Text(symbol)
                .font(.system(size: 14))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                if let sublabel = sublabel {
                    Text(sublabel)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
        }
    }
}

// MARK: - Nakshatra Data

enum NakshatraConstants {
    static let all: [String] = [
        "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
        "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
        "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
        "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
        "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"
    ]

    static func lord(for nakshatra: String) -> String {
        switch nakshatra {
        case "Ashwini", "Magha", "Mula": return "Ketu"
        case "Bharani", "Purva Phalguni", "Purva Ashadha": return "Venus"
        case "Krittika", "Uttara Phalguni", "Uttara Ashadha": return "Sun"
        case "Rohini", "Hasta", "Shravana": return "Moon"
        case "Mrigashira", "Chitra", "Dhanishta": return "Mars"
        case "Ardra", "Swati", "Shatabhisha": return "Rahu"
        case "Punarvasu", "Vishakha", "Purva Bhadrapada": return "Jupiter"
        case "Pushya", "Anuradha", "Uttara Bhadrapada": return "Saturn"
        case "Ashlesha", "Jyeshtha", "Revati": return "Mercury"
        default: return "Unknown"
        }
    }

    static func symbol(for nakshatra: String) -> String {
        switch nakshatra {
        case "Ashwini": return "🐴"
        case "Bharani": return "🔺"
        case "Krittika": return "🔥"
        case "Rohini": return "🐂"
        case "Mrigashira": return "🦌"
        case "Ardra": return "💧"
        case "Punarvasu": return "🏹"
        case "Pushya": return "🌸"
        case "Ashlesha": return "🐍"
        case "Magha": return "👑"
        case "Purva Phalguni": return "🛏"
        case "Uttara Phalguni": return "☀️"
        case "Hasta": return "✋"
        case "Chitra": return "💎"
        case "Swati": return "🌬"
        case "Vishakha": return "🌳"
        case "Anuradha": return "🪷"
        case "Jyeshtha": return "⭐"
        case "Mula": return "🌿"
        case "Purva Ashadha": return "🪭"
        case "Uttara Ashadha": return "🐘"
        case "Shravana": return "👂"
        case "Dhanishta": return "🥁"
        case "Shatabhisha": return "💫"
        case "Purva Bhadrapada": return "🔱"
        case "Uttara Bhadrapada": return "🐍"
        case "Revati": return "🐟"
        default: return "✧"
        }
    }

    static func quality(for nakshatra: String) -> String {
        switch nakshatra {
        case "Ashwini": return "Swift healing energy"
        case "Bharani": return "Creative restraint"
        case "Krittika": return "Purifying fire"
        case "Rohini": return "Fertile growth"
        case "Mrigashira": return "Curious seeking"
        case "Ardra": return "Transformative storms"
        case "Punarvasu": return "Renewal and return"
        case "Pushya": return "Nourishing care"
        case "Ashlesha": return "Mystical depth"
        case "Magha": return "Ancestral honor"
        case "Purva Phalguni": return "Creative pleasure"
        case "Uttara Phalguni": return "Generous patronage"
        case "Hasta": return "Skillful manifestation"
        case "Chitra": return "Brilliant crafting"
        case "Swati": return "Independent movement"
        case "Vishakha": return "Focused determination"
        case "Anuradha": return "Devoted friendship"
        case "Jyeshtha": return "Protective authority"
        case "Mula": return "Root transformation"
        case "Purva Ashadha": return "Invincible conviction"
        case "Uttara Ashadha": return "Final victory"
        case "Shravana": return "Deep listening"
        case "Dhanishta": return "Rhythmic wealth"
        case "Shatabhisha": return "Healing secrets"
        case "Purva Bhadrapada": return "Fiery transformation"
        case "Uttara Bhadrapada": return "Cosmic stability"
        case "Revati": return "Safe journeys"
        default: return "Cosmic energy"
        }
    }
}

// MARK: - Lagna (Vedic Ascendant) Data

enum LagnaConstants {
    static let all: [String] = [
        "Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya",
        "Tula", "Vrishchika", "Dhanu", "Makara", "Kumbha", "Meena"
    ]

    static func westernName(for lagna: String) -> String {
        switch lagna {
        case "Mesha": return "Aries"
        case "Vrishabha": return "Taurus"
        case "Mithuna": return "Gemini"
        case "Karka": return "Cancer"
        case "Simha": return "Leo"
        case "Kanya": return "Virgo"
        case "Tula": return "Libra"
        case "Vrishchika": return "Scorpio"
        case "Dhanu": return "Sagittarius"
        case "Makara": return "Capricorn"
        case "Kumbha": return "Aquarius"
        case "Meena": return "Pisces"
        default: return lagna
        }
    }

    static func element(for lagna: String) -> String {
        switch lagna {
        case "Mesha", "Simha", "Dhanu": return "Fire"
        case "Vrishabha", "Kanya", "Makara": return "Earth"
        case "Mithuna", "Tula", "Kumbha": return "Air"
        case "Karka", "Vrishchika", "Meena": return "Water"
        default: return "Ether"
        }
    }
}

// MARK: - Preview

#Preview("Essence Bar") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 40) {
            EssenceBar(
                moonNakshatra: "Rohini",
                lagna: "Makara",
                nakshatraLord: "Moon"
            )

            EssenceBar(
                moonNakshatra: nil,
                lagna: nil,
                nakshatraLord: nil
            )
        }
    }
}
