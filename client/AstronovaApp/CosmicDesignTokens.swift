import SwiftUI

// MARK: - Cosmic Design Tokens (Legacy Compatibility)
//
// This file provides backward compatibility with the old design token system.
// The new design system is split across:
// - CosmicDesignSystem.swift (spacing, sizing, elevation, components)
// - CosmicTypography.swift (fonts, text styles)
// - CosmicColors.swift (colors, gradients)
// - CosmicMotion.swift (animations, transitions)
//
// New code should import from those files directly.

// MARK: - Legacy Shadow Type

/// Legacy Shadow struct for backward compatibility
/// New code should use Cosmic.Elevation enum instead
struct Shadow {
    let color: SwiftUI.Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(color: SwiftUI.Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Legacy Elevation System

/// Legacy elevation system for backward compatibility
/// New code should use Cosmic.Elevation enum instead
struct CosmicElevation {
    static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
    static let low = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    static let high = Shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 8)

    static func glow(color: SwiftUI.Color = SwiftUI.Color.cosmicGold, opacity: Double = 0.3) -> Shadow {
        Shadow(color: color.opacity(opacity), radius: 20, x: 0, y: 0)
    }
}

// MARK: - Legacy View Modifiers

extension View {
    /// Legacy shadow modifier - use cosmicElevation() instead
    func cosmicShadow(_ elevation: Shadow) -> some View {
        self.shadow(color: elevation.color, radius: elevation.radius, x: elevation.x, y: elevation.y)
    }

    /// Legacy button modifier - use cosmicPrimaryButton() or ButtonStyle instead
    func cosmicButton(
        gradient: SwiftUI.LinearGradient = .cosmicAntiqueGold,
        radius: CGFloat = Cosmic.Radius.soft,
        height: CGFloat = Cosmic.ButtonHeight.large,
        elevation: Shadow = CosmicElevation.medium
    ) -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .cosmicShadow(elevation)
    }
}

// MARK: - Starburst Animation (Legacy Feature)

/// Starburst effect styles
enum StarburstStyle {
    case cosmic
    case celebration
    case subtle
}

extension View {
    /// Apply starburst particle effect
    func starburstEffect(
        style: StarburstStyle = .cosmic,
        duration: Double = 0.3
    ) -> some View {
        self.overlay(
            StarburstAnimationView(style: style, duration: duration)
        )
    }
}

/// Starburst particle animation view
struct StarburstAnimationView: View {
    let style: StarburstStyle
    let duration: Double
    @State private var isAnimating = false

    private var particleCount: Int {
        switch style {
        case .cosmic: return 12
        case .celebration: return 20
        case .subtle: return 6
        }
    }

    private var particleColor: Color {
        switch style {
        case .cosmic: return .cosmicGold
        case .celebration: return .cosmicCopper
        case .subtle: return .cosmicGold.opacity(0.5)
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(particleColor)
                    .frame(width: 4, height: 4)
                    .offset(particleOffset(for: index))
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.1 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: duration)) {
                isAnimating = true
            }
        }
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (2 * Double.pi / Double(particleCount))
        let distance: CGFloat = isAnimating ? 40 : 0
        return CGSize(
            width: CGFloat(cos(angle)) * distance,
            height: CGFloat(sin(angle)) * distance
        )
    }
}
