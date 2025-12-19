import SwiftUI

// MARK: - Cosmic Typography System
// Geometric Modern: Clean sans-serif with strong hierarchy and bold headlines

/// Typography scale following the Modern Mystic design system
enum CosmicTypography {

    // MARK: - Type Scale

    /// 44pt Bold - Hero headlines
    static let hero = Font.system(size: 44, weight: .bold, design: .default)

    /// 32pt Bold - Display headlines
    static let display = Font.system(size: 32, weight: .bold, design: .default)

    /// 26pt Semibold - Primary titles
    static let title1 = Font.system(size: 26, weight: .semibold, design: .default)

    /// 22pt Semibold - Secondary titles
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)

    /// 18pt Semibold - Headlines
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)

    /// 16pt Regular - Body text
    static let body = Font.system(size: 16, weight: .regular, design: .default)

    /// 16pt Medium - Emphasized body
    static let bodyEmphasis = Font.system(size: 16, weight: .medium, design: .default)

    /// 14pt Regular - Callout text
    static let callout = Font.system(size: 14, weight: .regular, design: .default)

    /// 14pt Medium - Emphasized callout
    static let calloutEmphasis = Font.system(size: 14, weight: .medium, design: .default)

    /// 12pt Medium - Caption text
    static let caption = Font.system(size: 12, weight: .medium, design: .default)

    /// 10pt Medium - Micro text
    static let micro = Font.system(size: 10, weight: .medium, design: .default)

    /// Monospaced for numbers/data
    static let mono = Font.system(size: 14, weight: .medium, design: .monospaced)

    /// Monospaced large for hero numbers
    static let monoLarge = Font.system(size: 32, weight: .bold, design: .monospaced)

    // MARK: - Tracking (Letter Spacing)

    enum Tracking {
        /// -0.5pt for hero text
        static let tight: CGFloat = -0.5
        /// -0.3pt for display text
        static let display: CGFloat = -0.3
        /// -0.2pt for titles
        static let title: CGFloat = -0.2
        /// 0pt - normal
        static let normal: CGFloat = 0
        /// 0.1pt for body text
        static let body: CGFloat = 0.1
        /// 0.2pt for callout
        static let callout: CGFloat = 0.2
        /// 0.3pt for captions
        static let caption: CGFloat = 0.3
        /// 0.5pt for micro text
        static let micro: CGFloat = 0.5
        /// 2pt for uppercase labels
        static let uppercase: CGFloat = 2
    }

    // MARK: - Line Height Multipliers

    enum LineHeight {
        /// 1.1 for hero text
        static let tight: CGFloat = 1.1
        /// 1.15 for display text
        static let display: CGFloat = 1.15
        /// 1.2 for titles
        static let title: CGFloat = 1.2
        /// 1.25 for headlines
        static let headline: CGFloat = 1.25
        /// 1.3 for callout
        static let callout: CGFloat = 1.3
        /// 1.35 for captions
        static let caption: CGFloat = 1.35
        /// 1.5 for body text
        static let body: CGFloat = 1.5
        /// 1.6 for relaxed reading
        static let relaxed: CGFloat = 1.6
    }
}

// MARK: - Font Extensions

extension Font {

    // MARK: - Primary Type Scale

    /// 44pt Bold - Hero headlines
    static var cosmicHero: Font { CosmicTypography.hero }

    /// 32pt Bold - Display headlines
    static var cosmicDisplay: Font { CosmicTypography.display }

    /// 26pt Semibold - Primary titles
    static var cosmicTitle1: Font { CosmicTypography.title1 }

    /// 22pt Semibold - Secondary titles
    static var cosmicTitle2: Font { CosmicTypography.title2 }

    /// 20pt Semibold - Tertiary titles (legacy alias)
    static var cosmicTitle3: Font { .system(size: 20, weight: .semibold) }

    /// 20pt Semibold - Section headlines (legacy alias)
    static var cosmicTitle: Font { .system(size: 20, weight: .semibold) }

    /// 18pt Semibold - Headlines
    static var cosmicHeadline: Font { CosmicTypography.headline }

    /// 16pt Regular - Body text
    static var cosmicBody: Font { CosmicTypography.body }

    /// 16pt Medium - Emphasized body
    static var cosmicBodyEmphasis: Font { CosmicTypography.bodyEmphasis }

    /// 14pt Regular - Callout text
    static var cosmicCallout: Font { CosmicTypography.callout }

    /// 14pt Medium - Emphasized callout
    static var cosmicCalloutEmphasis: Font { CosmicTypography.calloutEmphasis }

    /// 13pt Regular - Subheadline (legacy)
    static var cosmicSubheadline: Font { .system(size: 13, weight: .regular) }

    /// 13pt Regular - Footnote (legacy)
    static var cosmicFootnote: Font { .system(size: 13, weight: .regular) }

    /// 13pt Medium - Emphasized footnote (legacy)
    static var cosmicFootnoteEmphasis: Font { .system(size: 13, weight: .medium) }

    /// 12pt Medium - Caption text
    static var cosmicCaption: Font { CosmicTypography.caption }

    /// 12pt Medium - Caption emphasis (legacy alias)
    static var cosmicCaptionEmphasis: Font { .system(size: 12, weight: .medium) }

    /// 10pt Medium - Micro text
    static var cosmicMicro: Font { CosmicTypography.micro }

    /// 11pt Medium - Label (legacy)
    static var cosmicLabel: Font { .system(size: 11, weight: .medium) }

    // MARK: - Monospaced

    /// Monospaced for numbers/data
    static var cosmicMono: Font { CosmicTypography.mono }

    /// Monospaced large for hero numbers
    static var cosmicMonoLarge: Font { CosmicTypography.monoLarge }
}

// MARK: - Text Modifiers

extension View {
    /// Apply hero text styling with tight tracking
    func cosmicHeroStyle() -> some View {
        self
            .font(.cosmicHero)
            .tracking(CosmicTypography.Tracking.tight)
            .lineSpacing(4)
    }

    /// Apply display text styling
    func cosmicDisplayStyle() -> some View {
        self
            .font(.cosmicDisplay)
            .tracking(CosmicTypography.Tracking.display)
            .lineSpacing(4)
    }

    /// Apply title styling
    func cosmicTitleStyle() -> some View {
        self
            .font(.cosmicTitle1)
            .tracking(CosmicTypography.Tracking.title)
            .lineSpacing(2)
    }

    /// Apply body text styling with proper line height
    func cosmicBodyStyle() -> some View {
        self
            .font(.cosmicBody)
            .tracking(CosmicTypography.Tracking.body)
            .lineSpacing(6)
    }

    /// Apply uppercase label styling
    func cosmicUppercaseLabel() -> some View {
        self
            .font(.cosmicCaption)
            .tracking(CosmicTypography.Tracking.uppercase)
            .textCase(.uppercase)
    }

    /// Apply monospaced number styling
    func cosmicMonoStyle() -> some View {
        self
            .font(.cosmicMono)
            .monospacedDigit()
    }
}

// MARK: - Text Styles with Color

struct CosmicText: View {
    let text: String
    let style: Style

    enum Style {
        case hero
        case display
        case title1
        case title2
        case headline
        case body
        case bodySecondary
        case callout
        case caption
        case micro
        case uppercase
    }

    var body: some View {
        switch style {
        case .hero:
            Text(text)
                .font(.cosmicHero)
                .tracking(CosmicTypography.Tracking.tight)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .display:
            Text(text)
                .font(.cosmicDisplay)
                .tracking(CosmicTypography.Tracking.display)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .title1:
            Text(text)
                .font(.cosmicTitle1)
                .tracking(CosmicTypography.Tracking.title)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .title2:
            Text(text)
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .headline:
            Text(text)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .body:
            Text(text)
                .font(.cosmicBody)
                .tracking(CosmicTypography.Tracking.body)
                .lineSpacing(6)
                .foregroundStyle(Color.cosmicTextPrimary)

        case .bodySecondary:
            Text(text)
                .font(.cosmicBody)
                .tracking(CosmicTypography.Tracking.body)
                .lineSpacing(6)
                .foregroundStyle(Color.cosmicTextSecondary)

        case .callout:
            Text(text)
                .font(.cosmicCallout)
                .tracking(CosmicTypography.Tracking.callout)
                .foregroundStyle(Color.cosmicTextSecondary)

        case .caption:
            Text(text)
                .font(.cosmicCaption)
                .tracking(CosmicTypography.Tracking.caption)
                .foregroundStyle(Color.cosmicTextTertiary)

        case .micro:
            Text(text)
                .font(.cosmicMicro)
                .tracking(CosmicTypography.Tracking.micro)
                .foregroundStyle(Color.cosmicTextTertiary)

        case .uppercase:
            Text(text)
                .font(.cosmicCaption)
                .tracking(CosmicTypography.Tracking.uppercase)
                .textCase(.uppercase)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }
}

// MARK: - Gradient Text

extension View {
    /// Apply gold gradient to text
    func cosmicGoldGradient() -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: [.cosmicBrass, .cosmicGold, .cosmicCopper],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    /// Apply celestial gradient to text
    func cosmicCelestialGradient() -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: [.cosmicGold, .cosmicCopper, .cosmicAmethyst],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
