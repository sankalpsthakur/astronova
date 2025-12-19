import SwiftUI
import Darwin

// MARK: - Cosmic Pulse View
// The hero component showing your current Dasha - where you ARE in your cosmic journey
// This is uniquely Vedic - no Western astrology app has this concept

struct CosmicPulseView: View {
    let currentDasha: DashaInfo?
    var accuracyLevel: CompletenessLevel = .full
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var particlePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background glow layers
                glowLayers

                // Concentric progress arcs
                progressArcs

                // Central planet orb
                centralOrb

                // Planet glyph
                planetGlyph

                // Period info overlay
                periodInfo
            }
            .frame(height: 280)
        }
        .buttonStyle(.plain)
        .onAppear { startAnimations() }
    }

    // MARK: - Glow Layers

    private var glowLayers: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetColor.opacity(glowOpacity * 0.3),
                            planetColor.opacity(glowOpacity * 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseScale)

            // Inner concentrated glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetColor.opacity(glowOpacity * 0.6),
                            planetColor.opacity(glowOpacity * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale * 1.1)

            // Floating particles
            if !reduceMotion {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(planetColor.opacity(0.4))
                        .frame(width: 3, height: 3)
                        .offset(particleOffset(for: i))
                        .opacity(particleOpacity(for: i))
                }
            }
        }
    }

    // MARK: - Progress Arcs

    private var progressArcs: some View {
        ZStack {
            // Background arc (total period)
            Circle()
                .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: 3)
                .frame(width: 180, height: 180)

            // Progress arc (current position)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    AngularGradient(
                        colors: [planetColor.opacity(0.3), planetColor, planetColor.opacity(0.3)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            // Tick marks for years
            ForEach(0..<totalYears, id: \.self) { year in
                Rectangle()
                    .fill(year < currentYear ? planetColor : Color.cosmicTextTertiary.opacity(0.3))
                    .frame(width: 2, height: year < currentYear ? 10 : 6)
                    .offset(y: -90)
                    .rotationEffect(.degrees(Double(year) / Double(totalYears) * 360))
            }
        }
    }

    // MARK: - Central Orb

    private var centralOrb: some View {
        ZStack {
            // Orb background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetColor.opacity(0.3),
                            Color.cosmicNebula,
                            Color.cosmicVoid
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            // Orb border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [planetColor.opacity(0.6), planetColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
        }
        .scaleEffect(pulseScale * 0.98)
    }

    // MARK: - Planet Glyph

    private var planetGlyph: some View {
        VStack(spacing: Cosmic.Spacing.xs) {
            Text(planetSymbol)
                .font(.system(size: 44))
                .foregroundStyle(planetColor)
                .shadow(color: planetColor.opacity(0.5), radius: 8)

            Text(planetName.uppercased())
                .font(.cosmicCaptionEmphasis)
                .tracking(CosmicTypography.Tracking.uppercase)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }

    // MARK: - Period Info

    private var periodInfo: some View {
        VStack {
            // Accuracy indicator at top when not full
            if accuracyLevel != .full {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: accuracyLevel.icon)
                        .font(.system(size: 10))
                    Text(accuracyDescription)
                        .font(.cosmicMicro)
                }
                .foregroundStyle(accuracyLevel.color)
                .padding(.horizontal, Cosmic.Spacing.sm)
                .padding(.vertical, Cosmic.Spacing.xs)
                .background(accuracyLevel.color.opacity(0.15), in: Capsule())
                .padding(.top, Cosmic.Spacing.sm)
            }

            Spacer()

            VStack(spacing: Cosmic.Spacing.xs) {
                // Year progress
                Text("Year \(currentYear) of \(totalYears)")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)

                // Period tagline
                Text(periodTagline)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.xl)
            }
            .padding(.bottom, Cosmic.Spacing.sm)
        }
    }

    private var accuracyDescription: String {
        switch accuracyLevel {
        case .minimal:
            return "Basic timing"
        case .basic:
            return "Basic timing"
        case .enhanced:
            return "Add place for full accuracy"
        case .full:
            return "Full precision"
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Breathing pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }

        // Glow intensity
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }

        // Particle orbit
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particlePhase = .pi * 2
        }
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = (CGFloat(index) / 8.0) * .pi * 2 + particlePhase
        let radius: CGFloat = 100 + CGFloat(index % 3) * 15
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius * 0.6
        )
    }

    private func particleOpacity(for index: Int) -> Double {
        let base = 0.3 + Double(index % 3) * 0.2
        let sinValue: Double = Darwin.sin(particlePhase + Double(index))
        return base * (0.5 + sinValue * 0.5)
    }

    // MARK: - Computed Properties

    private var planetName: String {
        currentDasha?.planet ?? "Awakening"
    }

    private var planetSymbol: String {
        guard let planet = currentDasha?.planet else { return "✧" }
        return DashaConstants.symbol(for: planet)
    }

    private var planetColor: Color {
        guard let planet = currentDasha?.planet else { return .cosmicGold }
        return DashaConstants.color(for: planet)
    }

    private var currentYear: Int {
        currentDasha?.currentYear ?? 1
    }

    private var totalYears: Int {
        currentDasha?.totalYears ?? 7
    }

    private var progressFraction: CGFloat {
        guard totalYears > 0 else { return 0 }
        return CGFloat(currentYear) / CGFloat(totalYears)
    }

    private var periodTagline: String {
        guard let planet = currentDasha?.planet else {
            return "Your cosmic rhythm awaits"
        }
        return DashaConstants.tagline(for: planet)
    }
}

// MARK: - Dasha Info Model

struct DashaInfo {
    let planet: String
    let startDate: Date
    let endDate: Date
    let currentYear: Int
    let totalYears: Int

    var remainingYears: Int {
        totalYears - currentYear
    }
}

// MARK: - Dasha Constants

enum DashaConstants {
    static func symbol(for planet: String) -> String {
        switch planet.lowercased() {
        case "sun", "surya": return "☉"
        case "moon", "chandra": return "☽"
        case "mars", "mangal": return "♂"
        case "mercury", "budha": return "☿"
        case "jupiter", "guru": return "♃"
        case "venus", "shukra": return "♀"
        case "saturn", "shani": return "♄"
        case "rahu": return "☊"
        case "ketu": return "☋"
        default: return "✧"
        }
    }

    static func color(for planet: String) -> Color {
        switch planet.lowercased() {
        case "sun", "surya": return .planetSun
        case "moon", "chandra": return .planetMoon
        case "mars", "mangal": return .planetMars
        case "mercury", "budha": return .planetMercury
        case "jupiter", "guru": return .planetJupiter
        case "venus", "shukra": return .planetVenus
        case "saturn", "shani": return .planetSaturn
        case "rahu": return .cosmicAmethyst
        case "ketu": return .cosmicCopper
        default: return .cosmicGold
        }
    }

    static func tagline(for planet: String) -> String {
        switch planet.lowercased() {
        case "sun", "surya":
            return "Illuminate your purpose"
        case "moon", "chandra":
            return "Honor your inner tides"
        case "mars", "mangal":
            return "Channel your fire wisely"
        case "mercury", "budha":
            return "Speak your truth clearly"
        case "jupiter", "guru":
            return "Expand through wisdom"
        case "venus", "shukra":
            return "Create beauty everywhere"
        case "saturn", "shani":
            return "Build with patience"
        case "rahu":
            return "Embrace the unknown"
        case "ketu":
            return "Release and transcend"
        default:
            return "Flow with cosmic rhythm"
        }
    }

    static func totalYears(for planet: String) -> Int {
        switch planet.lowercased() {
        case "sun", "surya": return 6
        case "moon", "chandra": return 10
        case "mars", "mangal": return 7
        case "mercury", "budha": return 17
        case "jupiter", "guru": return 16
        case "venus", "shukra": return 20
        case "saturn", "shani": return 19
        case "rahu": return 18
        case "ketu": return 7
        default: return 7
        }
    }
}

// MARK: - Empty State

struct CosmicPulseEmptyView: View {
    let onSetup: () -> Void

    @State private var shimmer: CGFloat = 0

    var body: some View {
        Button(action: onSetup) {
            ZStack {
                // Dormant glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cosmicGold.opacity(0.15),
                                Color.cosmicAmethyst.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                // Dormant orb
                Circle()
                    .stroke(Color.cosmicGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                // Content
                VStack(spacing: Cosmic.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.cosmicGold.opacity(0.6))

                    Text("Awaken Your Pulse")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("Add birth details to reveal\nyour cosmic rhythm")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 280)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Cosmic Pulse - Active") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        CosmicPulseView(
            currentDasha: DashaInfo(
                planet: "Mars",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 365 * 7),
                currentYear: 3,
                totalYears: 7
            ),
            onTap: {}
        )
    }
}

#Preview("Cosmic Pulse - Empty") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        CosmicPulseEmptyView(onSetup: {})
    }
}
