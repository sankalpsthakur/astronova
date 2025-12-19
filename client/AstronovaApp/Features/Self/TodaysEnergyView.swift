import SwiftUI

// MARK: - Today's Energy View
// Shows current planetary strengths based on transits to your chart
// Live, dynamic, uniquely personal

struct TodaysEnergyView: View {
    let planetaryStrengths: [PlanetaryStrength]
    let dominantPlanet: String?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            header

            // Energy bars
            energyBars

            // Dominant energy callout
            if let dominant = dominantPlanet {
                dominantCallout(planet: dominant)
            }
        }
        .padding(Cosmic.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text("Today's Energy")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Planetary influences active now")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()

            // Live indicator
            HStack(spacing: Cosmic.Spacing.xxs) {
                Circle()
                    .fill(Color.cosmicSuccess)
                    .frame(width: 6, height: 6)
                Text("Live")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
    }

    // MARK: - Energy Bars

    private var energyBars: some View {
        let displayPlanets = isExpanded ? planetaryStrengths : Array(planetaryStrengths.prefix(4))

        return VStack(spacing: Cosmic.Spacing.sm) {
            ForEach(displayPlanets) { strength in
                EnergyBar(strength: strength)
            }

            if planetaryStrengths.count > 4 {
                Button {
                    withAnimation(.cosmicSpring) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Show less" : "Show all planets")
                            .font(.cosmicCaption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.cosmicGold)
                }
                .buttonStyle(.plain)
                .padding(.top, Cosmic.Spacing.xxs)
            }
        }
    }

    // MARK: - Dominant Callout

    private func dominantCallout(planet: String) -> some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Text(DashaConstants.symbol(for: planet))
                .font(.system(size: 16))
                .foregroundStyle(DashaConstants.color(for: planet))

            Text("\(planet) energy is amplified today")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(Cosmic.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(DashaConstants.color(for: planet).opacity(0.1))
        )
    }
}

// MARK: - Energy Bar

private struct EnergyBar: View {
    let strength: PlanetaryStrength

    @State private var animatedValue: CGFloat = 0

    var body: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Planet symbol
            Text(DashaConstants.symbol(for: strength.planet))
                .font(.system(size: 14))
                .foregroundStyle(DashaConstants.color(for: strength.planet))
                .frame(width: 20)

            // Planet name
            Text(strength.planet)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .frame(width: 55, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cosmicTextTertiary.opacity(0.15))
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DashaConstants.color(for: strength.planet).opacity(0.6),
                                    DashaConstants.color(for: strength.planet)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedValue, height: 6)
                }
            }
            .frame(height: 6)

            // Percentage
            Text("\(Int(strength.value * 100))%")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
                .frame(width: 32, alignment: .trailing)
                .monospacedDigit()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animatedValue = CGFloat(strength.value)
            }
        }
    }
}

// MARK: - Planetary Strength Model

struct PlanetaryStrength: Identifiable {
    let id = UUID()
    let planet: String
    let value: Double // 0.0 to 1.0

    static let sample: [PlanetaryStrength] = [
        PlanetaryStrength(planet: "Mars", value: 0.85),
        PlanetaryStrength(planet: "Sun", value: 0.72),
        PlanetaryStrength(planet: "Jupiter", value: 0.65),
        PlanetaryStrength(planet: "Saturn", value: 0.45),
        PlanetaryStrength(planet: "Moon", value: 0.58),
        PlanetaryStrength(planet: "Mercury", value: 0.40),
        PlanetaryStrength(planet: "Venus", value: 0.52),
        PlanetaryStrength(planet: "Rahu", value: 0.30),
        PlanetaryStrength(planet: "Ketu", value: 0.25)
    ].sorted { $0.value > $1.value }
}

// MARK: - Empty State

struct TodaysEnergyEmptyView: View {
    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28))
                .foregroundStyle(Color.cosmicTextTertiary)

            Text("Energy Reading Unavailable")
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)

            Text("Add your birth details to see\nhow today's planets affect you")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Cosmic.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.4))
        )
    }
}

// MARK: - Preview

#Preview("Today's Energy") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 20) {
            TodaysEnergyView(
                planetaryStrengths: PlanetaryStrength.sample,
                dominantPlanet: "Mars"
            )
            .padding()

            TodaysEnergyEmptyView()
                .padding()
        }
    }
}
