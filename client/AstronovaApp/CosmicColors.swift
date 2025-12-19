import SwiftUI

// MARK: - Cosmic Color System
// Modern Mystic: Ancient astrological wisdom through contemporary design
// Equal parity between light and dark modes

extension SwiftUI.Color {

    // MARK: - Background Hierarchy

    /// Deepest black - true void (#08080C dark / #FAF6F0 light)
    static let cosmicVoid = SwiftUI.Color(
        light: SwiftUI.Color(hex: "FAF6F0"),
        dark: SwiftUI.Color(hex: "08080C")
    )

    /// Primary background (#0E0E14 dark / #FAF6F0 light)
    static let cosmicCosmos = SwiftUI.Color(
        light: SwiftUI.Color(hex: "FAF6F0"),
        dark: SwiftUI.Color(hex: "0E0E14")
    )

    /// Elevated surfaces (#16161E dark / #F2EDE5 light)
    static let cosmicNebula = SwiftUI.Color(
        light: SwiftUI.Color(hex: "F2EDE5"),
        dark: SwiftUI.Color(hex: "16161E")
    )

    /// Cards and containers (#1E1E28 dark / #E8E2D8 light)
    static let cosmicStardust = SwiftUI.Color(
        light: SwiftUI.Color(hex: "E8E2D8"),
        dark: SwiftUI.Color(hex: "1E1E28")
    )

    /// Hover/interactive states (#2A2A36 dark / #D8D0C4 light)
    static let cosmicTwilight = SwiftUI.Color(
        light: SwiftUI.Color(hex: "D8D0C4"),
        dark: SwiftUI.Color(hex: "2A2A36")
    )

    // MARK: - Legacy Background Aliases

    /// Base background - Maps to cosmos
    static let cosmicBackground = cosmicCosmos

    /// Dark background sections
    static let cosmicBackgroundDark = SwiftUI.Color(
        light: SwiftUI.Color(hex: "16161E"),
        dark: SwiftUI.Color(hex: "08080C")
    )

    /// Surface color - Maps to stardust
    static let cosmicSurface = cosmicStardust

    /// Secondary surface - Maps to nebula
    static let cosmicSurfaceSecondary = cosmicNebula

    // MARK: - Text Colors

    /// Primary text (#F5F0E6 dark / #1A1612 light)
    static let cosmicTextPrimary = SwiftUI.Color(
        light: SwiftUI.Color(hex: "1A1612"),
        dark: SwiftUI.Color(hex: "F5F0E6")
    )

    /// Secondary text (#B8B0A0 dark / #4A4540 light)
    static let cosmicTextSecondary = SwiftUI.Color(
        light: SwiftUI.Color(hex: "4A4540"),
        dark: SwiftUI.Color(hex: "B8B0A0")
    )

    /// Tertiary text / disabled (#706860 dark / #7A756C light)
    static let cosmicTextTertiary = SwiftUI.Color(
        light: SwiftUI.Color(hex: "7A756C"),
        dark: SwiftUI.Color(hex: "706860")
    )

    // MARK: - Accent Colors

    /// Primary gold accent (#D4A853 dark / #B8923D light)
    static let cosmicGold = SwiftUI.Color(
        light: SwiftUI.Color(hex: "B8923D"),
        dark: SwiftUI.Color(hex: "D4A853")
    )

    /// Secondary brass accent (#B08D57 dark / #8C6B35 light)
    static let cosmicBrass = SwiftUI.Color(
        light: SwiftUI.Color(hex: "8C6B35"),
        dark: SwiftUI.Color(hex: "B08D57")
    )

    /// Warm copper accent (#C67D4D dark / #A65A30 light)
    static let cosmicCopper = SwiftUI.Color(
        light: SwiftUI.Color(hex: "A65A30"),
        dark: SwiftUI.Color(hex: "C67D4D")
    )

    /// Spiritual purple accent (#9B7ED9 dark / #7B5EB8 light)
    static let cosmicAmethyst = SwiftUI.Color(
        light: SwiftUI.Color(hex: "7B5EB8"),
        dark: SwiftUI.Color(hex: "9B7ED9")
    )

    // MARK: - Legacy Accent Aliases

    /// Primary color - Maps to gold
    static let cosmicPrimary = cosmicGold

    /// Secondary color - Maps to amethyst
    static let cosmicSecondary = cosmicAmethyst

    /// Accent color - Maps to copper
    static let cosmicAccent = cosmicCopper

    // MARK: - Semantic Colors

    /// Success - Muted sage green (#4CAF7C)
    static let cosmicSuccess = SwiftUI.Color(
        light: SwiftUI.Color(hex: "3D9968"),
        dark: SwiftUI.Color(hex: "4CAF7C")
    )

    /// Warning - Amber (#E6A040)
    static let cosmicWarning = SwiftUI.Color(
        light: SwiftUI.Color(hex: "CC8A30"),
        dark: SwiftUI.Color(hex: "E6A040")
    )

    /// Error - Terracotta red (#C45C5C)
    static let cosmicError = SwiftUI.Color(
        light: SwiftUI.Color(hex: "B04848"),
        dark: SwiftUI.Color(hex: "C45C5C")
    )

    /// Info - Steel blue (#5C8EC4)
    static let cosmicInfo = SwiftUI.Color(
        light: SwiftUI.Color(hex: "4A7AB0"),
        dark: SwiftUI.Color(hex: "5C8EC4")
    )

    /// Teal - Flowing energy (#4ECDC4)
    static let cosmicTeal = SwiftUI.Color(
        light: SwiftUI.Color(hex: "3DBDB5"),
        dark: SwiftUI.Color(hex: "4ECDC4")
    )

    /// Premium - Gold (same as cosmicGold)
    static let cosmicPremium = cosmicGold

    // MARK: - Planet Colors (Refined Ancient Feel)

    /// Sun - Aged gold (#E8A23D)
    static let planetSun = SwiftUI.Color(hex: "E8A23D")

    /// Moon - Pearl silver (#E0DCD0)
    static let planetMoon = SwiftUI.Color(
        light: SwiftUI.Color(hex: "C8C4B8"),
        dark: SwiftUI.Color(hex: "E0DCD0")
    )

    /// Mercury - Verdigris cyan (#6CB8C8)
    static let planetMercury = SwiftUI.Color(hex: "6CB8C8")

    /// Venus - Rose copper (#D4A0A8)
    static let planetVenus = SwiftUI.Color(hex: "D4A0A8")

    /// Mars - Iron oxide red (#B84C4C)
    static let planetMars = SwiftUI.Color(hex: "B84C4C")

    /// Jupiter - Royal purple (#9070C0)
    static let planetJupiter = SwiftUI.Color(hex: "9070C0")

    /// Saturn - Amber ochre (#A08050 light / #C9A86C dark)
    static let planetSaturn = SwiftUI.Color(
        light: SwiftUI.Color(hex: "A08050"),
        dark: SwiftUI.Color(hex: "C9A86C")
    )

    /// Uranus - Patina blue (#70B8D0)
    static let planetUranus = SwiftUI.Color(hex: "70B8D0")

    /// Neptune - Deep lapis (#5070B0)
    static let planetNeptune = SwiftUI.Color(hex: "5070B0")

    /// Pluto - Ash violet (#786878)
    static let planetPluto = SwiftUI.Color(hex: "786878")

    // MARK: - Zodiac Sign Colors

    static let zodiacAries = planetMars
    static let zodiacTaurus = cosmicCopper
    static let zodiacGemini = planetMercury
    static let zodiacCancer = planetMoon
    static let zodiacLeo = planetSun
    static let zodiacVirgo = SwiftUI.Color(hex: "8A9A70")
    static let zodiacLibra = planetVenus
    static let zodiacScorpio = SwiftUI.Color(hex: "8B4040")
    static let zodiacSagittarius = planetJupiter
    static let zodiacCapricorn = planetSaturn
    static let zodiacAquarius = planetUranus
    static let zodiacPisces = planetNeptune

    // MARK: - Chart Colors

    /// Ascendant line color
    static let chartAscendant = cosmicGold

    /// House cusp colors
    static let chartHouseCusp = SwiftUI.Color(
        light: SwiftUI.Color(hex: "8C8880"),
        dark: SwiftUI.Color(hex: "4A4640")
    )

    /// Aspect colors
    static let aspectConjunction = cosmicGold
    static let aspectOpposition = planetMars
    static let aspectTrine = SwiftUI.Color(hex: "4CAF7C")
    static let aspectSquare = SwiftUI.Color(hex: "C45C5C")
    static let aspectSextile = planetMercury
}

// MARK: - Gradients

extension SwiftUI.LinearGradient {

    /// Celestial dawn gradient - Gold to copper to amethyst
    static let cosmicCelestialDawn = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.cosmicGold,
            SwiftUI.Color.cosmicCopper,
            SwiftUI.Color.cosmicAmethyst
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Deep space gradient - Void to cosmos with amethyst hint
    static let cosmicDeepSpace = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.cosmicVoid,
            SwiftUI.Color.cosmicCosmos,
            SwiftUI.Color.cosmicAmethyst.opacity(0.1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Antique gold gradient - Metallic brass to gold to copper
    static let cosmicAntiqueGold = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.cosmicBrass,
            SwiftUI.Color.cosmicGold,
            SwiftUI.Color.cosmicCopper
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Parchment glow - Warm light mode gradient
    static let cosmicParchmentGlow = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color(hex: "FAF6F0"),
            SwiftUI.Color(hex: "F2EDE5"),
            SwiftUI.Color.cosmicGold.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Legacy Gradient Aliases

    /// Primary gradient - Maps to antique gold
    static let cosmicPrimaryGradient = cosmicAntiqueGold

    /// Warm gradient - For CTAs
    static let cosmicWarmGradient = cosmicCelestialDawn

    /// Cool gradient - For informational elements
    static let cosmicCoolGradient = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.planetMercury,
            SwiftUI.Color.planetNeptune,
            SwiftUI.Color.cosmicAmethyst
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Aurora gradient - Full spectrum
    static let cosmicAuroraGradient = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.cosmicCopper,
            SwiftUI.Color.cosmicAmethyst,
            SwiftUI.Color.planetMercury
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sunset gradient
    static let cosmicSunsetGradient = SwiftUI.LinearGradient(
        colors: [
            SwiftUI.Color.planetMars,
            SwiftUI.Color.cosmicCopper,
            SwiftUI.Color.cosmicGold
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension SwiftUI.RadialGradient {

    /// Glass overlay for glassmorphism effects
    static let cosmicGlass = SwiftUI.RadialGradient(
        colors: [SwiftUI.Color.white.opacity(0.08), SwiftUI.Color.clear],
        center: .center,
        startRadius: 20,
        endRadius: 150
    )

    /// Gold glow for focus states
    static let cosmicGoldGlow = SwiftUI.RadialGradient(
        colors: [SwiftUI.Color.cosmicGold.opacity(0.3), SwiftUI.Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 80
    )

    /// Customizable glow effect
    static func cosmicGlow(color: SwiftUI.Color, opacity: Double = 0.3) -> SwiftUI.RadialGradient {
        SwiftUI.RadialGradient(
            colors: [color.opacity(opacity), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: 80
        )
    }

    /// Star field background
    static let cosmicStarfield = SwiftUI.RadialGradient(
        colors: [
            SwiftUI.Color.cosmicNebula,
            SwiftUI.Color.cosmicCosmos,
            SwiftUI.Color.cosmicVoid
        ],
        center: .center,
        startRadius: 50,
        endRadius: 400
    )
}

// MARK: - Angular Gradients

extension SwiftUI.AngularGradient {

    /// Zodiac wheel gradient
    static let cosmicZodiacWheel = SwiftUI.AngularGradient(
        colors: [
            SwiftUI.Color.zodiacAries,
            SwiftUI.Color.zodiacTaurus,
            SwiftUI.Color.zodiacGemini,
            SwiftUI.Color.zodiacCancer,
            SwiftUI.Color.zodiacLeo,
            SwiftUI.Color.zodiacVirgo,
            SwiftUI.Color.zodiacLibra,
            SwiftUI.Color.zodiacScorpio,
            SwiftUI.Color.zodiacSagittarius,
            SwiftUI.Color.zodiacCapricorn,
            SwiftUI.Color.zodiacAquarius,
            SwiftUI.Color.zodiacPisces,
            SwiftUI.Color.zodiacAries
        ],
        center: .center
    )
}

// MARK: - Helper Initializers

extension SwiftUI.Color {

    /// Initialize color with separate light and dark mode values
    init(light: SwiftUI.Color, dark: SwiftUI.Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        self = light
        #endif
    }

    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Initialize color with asset name and fallback
    init(_ name: String, fallback: SwiftUI.Color) {
        #if canImport(UIKit)
        if UIColor(named: name) != nil {
            self.init(name)
        } else {
            self = fallback
        }
        #else
        self = fallback
        #endif
    }
}

// MARK: - Color Utilities

extension SwiftUI.Color {

    /// Returns color suitable for text on this background
    var contrastingText: SwiftUI.Color {
        // Simplified contrast check - in production use proper luminance calculation
        return .cosmicTextPrimary
    }

    /// Adjusts color brightness
    func brightness(_ amount: Double) -> SwiftUI.Color {
        #if canImport(UIKit)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: Double(hue),
                     saturation: Double(saturation),
                     brightness: Double(brightness) + amount,
                     opacity: Double(alpha))
        #else
        return self
        #endif
    }
}
