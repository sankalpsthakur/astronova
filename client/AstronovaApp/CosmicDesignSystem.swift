import SwiftUI

// MARK: - Cosmic Design System
// Modern Mystic: Ancient astrological wisdom through contemporary geometric design

/// Unified design tokens for the Astronova app
enum Cosmic {

    // MARK: - Spacing (4pt base unit)

    enum Spacing {
        /// 2pt - Hairline separations
        static let hair: CGFloat = 2
        /// 4pt - Tight groupings
        static let xxs: CGFloat = 4
        /// 8pt - Related items
        static let xs: CGFloat = 8
        /// 12pt - Component internal spacing
        static let sm: CGFloat = 12
        /// 16pt - Standard gaps
        static let md: CGFloat = 16
        /// 20pt - Screen margins
        static let screen: CGFloat = 20
        /// 24pt - Section spacing
        static let lg: CGFloat = 24
        /// 32pt - Major sections
        static let xl: CGFloat = 32
        /// 48pt - Hero areas
        static let xxl: CGFloat = 48
        /// 64pt - Dramatic breaks
        static let mega: CGFloat = 64
        /// 96pt - Full-bleed sections
        static let ultra: CGFloat = 96

        // Legacy aliases for backward compatibility
        static let m: CGFloat = md
        static let s: CGFloat = sm
        static let l: CGFloat = lg
    }

    // MARK: - Corner Radii

    enum Radius {
        /// 6pt - Chips, tags
        static let subtle: CGFloat = 6
        /// 10pt - Buttons, inputs
        static let soft: CGFloat = 10
        /// 16pt - Standard cards
        static let card: CGFloat = 16
        /// 24pt - Sheets, dialogs
        static let modal: CGFloat = 24
        /// 28pt - Featured cards
        static let hero: CGFloat = 28
        /// Full circular
        static let orb: CGFloat = 9999

        // Legacy aliases
        static let chip: CGFloat = subtle
        static let button: CGFloat = soft
        static let cardLarge: CGFloat = modal
        static let prominent: CGFloat = hero
        static let pill: CGFloat = orb
    }

    // MARK: - Icon Sizes

    enum IconSize {
        /// 16pt
        static let xs: CGFloat = 16
        /// 20pt
        static let sm: CGFloat = 20
        /// 24pt
        static let md: CGFloat = 24
        /// 32pt
        static let lg: CGFloat = 32
        /// 48pt
        static let xl: CGFloat = 48
        /// 72pt
        static let xxl: CGFloat = 72

        // Legacy aliases
        static let s: CGFloat = sm
        static let m: CGFloat = md
        static let l: CGFloat = lg
    }

    // MARK: - Button Heights

    enum ButtonHeight {
        /// 44pt - Compact buttons (minimum touch target)
        static let small: CGFloat = 44
        /// 48pt - Standard buttons
        static let medium: CGFloat = 48
        /// 52pt - Primary CTA buttons
        static let large: CGFloat = 52
        /// 56pt - Hero buttons
        static let hero: CGFloat = 56
    }

    // MARK: - Touch Targets

    enum TouchTarget {
        /// 44pt - Minimum touch target (Apple HIG)
        static let minimum: CGFloat = 44
        /// 48pt - Comfortable touch target
        static let comfortable: CGFloat = 48
        /// 56pt - Large touch target
        static let large: CGFloat = 56
    }

    // MARK: - Layout Metrics

    enum Layout {
        /// 56pt - Minimum list row height
        static let listRowHeight: CGFloat = 56
        /// 48pt - Input field height
        static let inputHeight: CGFloat = 48
        /// 64pt - Navigation bar height
        static let navBarHeight: CGFloat = 64
        /// 83pt - Tab bar height (with home indicator)
        static let tabBarHeight: CGFloat = 83
        /// Maximum content width for readability
        static let maxContentWidth: CGFloat = 428
    }

    // MARK: - Elevation (Shadows)

    enum Elevation {
        case none
        case subtle
        case low
        case medium
        case high
        case glow(Color)

        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none:
                return (.clear, 0, 0, 0)
            case .subtle:
                return (Color.black.opacity(0.04), 4, 0, 1)
            case .low:
                return (Color.black.opacity(0.08), 8, 0, 2)
            case .medium:
                return (Color.black.opacity(0.12), 16, 0, 4)
            case .high:
                return (Color.black.opacity(0.16), 24, 0, 8)
            case .glow(let color):
                return (color.opacity(0.3), 20, 0, 0)
            }
        }
    }

    // MARK: - Blur

    enum Blur {
        /// 8pt - Subtle blur
        static let subtle: CGFloat = 8
        /// 16pt - Medium blur
        static let medium: CGFloat = 16
        /// 24pt - Heavy blur
        static let heavy: CGFloat = 24
        /// 32pt - Overlay blur
        static let overlay: CGFloat = 32
    }

    // MARK: - Opacity

    enum Opacity {
        /// 0.04 - Barely visible
        static let ghost: Double = 0.04
        /// 0.08 - Subtle overlay
        static let subtle: Double = 0.08
        /// 0.15 - Light overlay
        static let light: Double = 0.15
        /// 0.3 - Medium overlay
        static let medium: Double = 0.3
        /// 0.5 - Half opacity
        static let half: Double = 0.5
        /// 0.7 - Heavy overlay
        static let heavy: Double = 0.7
        /// 0.85 - Almost opaque
        static let dense: Double = 0.85
    }

    // MARK: - Border Width

    enum Border {
        /// 0.5pt - Hairline border
        static let hairline: CGFloat = 0.5
        /// 1pt - Standard border
        static let thin: CGFloat = 1
        /// 1.5pt - Medium border
        static let medium: CGFloat = 1.5
        /// 2pt - Thick border
        static let thick: CGFloat = 2
        /// 3pt - Accent border
        static let accent: CGFloat = 3
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply cosmic elevation shadow
    func cosmicElevation(_ elevation: Cosmic.Elevation) -> some View {
        let shadow = elevation.shadow
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Ensures minimum touch target size (Apple HIG)
    func accessibleTouchTarget(minSize: CGFloat = Cosmic.TouchTarget.minimum) -> some View {
        self.frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }

    /// Square touch target for icon-only buttons
    func accessibleIconButton(size: CGFloat = Cosmic.TouchTarget.minimum) -> some View {
        self.frame(width: size, height: size)
            .contentShape(Rectangle())
    }

    /// Standard card styling
    func cosmicCard(
        background: Color = .cosmicSurface,
        radius: CGFloat = Cosmic.Radius.card,
        padding: CGFloat = Cosmic.Spacing.screen,
        elevation: Cosmic.Elevation = .low
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: Cosmic.Border.hairline)
            )
            .cosmicElevation(elevation)
    }

    /// Featured card with accent border
    func cosmicFeaturedCard(
        background: Color = .cosmicSurface,
        accentColor: Color = .cosmicGold,
        radius: CGFloat = Cosmic.Radius.hero
    ) -> some View {
        self
            .padding(Cosmic.Spacing.screen)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Cosmic.Border.thick
                    )
            )
            .cosmicElevation(.medium)
    }

    /// Primary button styling
    func cosmicPrimaryButton() -> some View {
        self
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicVoid)
            .frame(height: Cosmic.ButtonHeight.large)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.cosmicBrass, .cosmicGold, .cosmicCopper],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            .cosmicElevation(.glow(.cosmicGold))
    }

    /// Secondary button styling
    func cosmicSecondaryButton() -> some View {
        self
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicTextPrimary)
            .frame(height: Cosmic.ButtonHeight.large)
            .frame(maxWidth: .infinity)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.3), lineWidth: Cosmic.Border.thin)
            )
    }

    /// Ghost/text button styling
    func cosmicGhostButton() -> some View {
        self
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicGold)
    }

    /// Input field styling
    func cosmicInputField(isFocused: Bool = false) -> some View {
        self
            .padding(.horizontal, Cosmic.Spacing.md)
            .frame(height: Cosmic.Layout.inputHeight)
            .background(Color.cosmicSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .stroke(
                        isFocused ? Color.cosmicGold.opacity(0.6) : Color.cosmicTextTertiary.opacity(0.2),
                        lineWidth: Cosmic.Border.thin
                    )
            )
    }

    /// Chip/tag styling
    func cosmicChip(
        background: Color = .cosmicSurface,
        foreground: Color = .cosmicTextSecondary
    ) -> some View {
        self
            .font(.cosmicCaption)
            .foregroundStyle(foreground)
            .padding(.horizontal, Cosmic.Spacing.sm)
            .padding(.vertical, Cosmic.Spacing.xxs)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous))
    }

    /// Screen edge padding
    func cosmicScreenPadding() -> some View {
        self.padding(.horizontal, Cosmic.Spacing.screen)
    }

    /// Section spacing
    func cosmicSectionSpacing() -> some View {
        self.padding(.vertical, Cosmic.Spacing.xl)
    }
}

// MARK: - Button Styles

struct CosmicPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicVoid)
            .frame(height: Cosmic.ButtonHeight.large)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.cosmicBrass, .cosmicGold, .cosmicCopper],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            .cosmicElevation(configuration.isPressed ? .subtle : .glow(.cosmicGold))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.cosmicQuick, value: configuration.isPressed)
    }
}

struct CosmicSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicTextPrimary)
            .frame(height: Cosmic.ButtonHeight.large)
            .frame(maxWidth: .infinity)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .stroke(
                        configuration.isPressed ? Color.cosmicGold.opacity(0.6) : Color.cosmicGold.opacity(0.3),
                        lineWidth: Cosmic.Border.thin
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.cosmicQuick, value: configuration.isPressed)
    }
}

struct CosmicGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cosmicBodyEmphasis)
            .foregroundStyle(Color.cosmicGold)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.cosmicQuick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CosmicPrimaryButtonStyle {
    static var cosmicPrimary: CosmicPrimaryButtonStyle { CosmicPrimaryButtonStyle() }
}

extension ButtonStyle where Self == CosmicSecondaryButtonStyle {
    static var cosmicSecondary: CosmicSecondaryButtonStyle { CosmicSecondaryButtonStyle() }
}

extension ButtonStyle where Self == CosmicGhostButtonStyle {
    static var cosmicGhost: CosmicGhostButtonStyle { CosmicGhostButtonStyle() }
}
