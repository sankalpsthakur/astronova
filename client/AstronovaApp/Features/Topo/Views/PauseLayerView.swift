import SwiftUI

struct PauseLayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var log = PauseLogStore.shared
    @State private var protocols: [PauseProtocol] = []
    @State private var loadError: String?
    @State private var sessionStarter: PauseSessionStarter?

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                topBar
                header
                if let loadError {
                    errorView(loadError)
                } else if protocols.isEmpty {
                    ProgressView()
                        .tint(Color.cosmicTextPrimary)
                        .padding(.top, 60)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        if let recent = recentChip {
                            recent
                                .padding(.horizontal, 20)
                                .padding(.bottom, 18)
                        }
                        VStack(spacing: 14) {
                            ForEach(protocols) { proto in
                                EmotionCard(
                                    proto: proto,
                                    recentCount: log.recentCount(emotion: proto.emotion),
                                    onPick: { intensity in
                                        sessionStarter = PauseSessionStarter(proto: proto, moodBefore: intensity)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    footer
                }
            }
        }
        .task { load() }
        .fullScreenCover(item: $sessionStarter) { starter in
            ProtocolRunnerView(proto: starter.proto, moodBefore: starter.moodBefore)
        }
    }

    // MARK: - Subviews

    private var backdrop: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color.cosmicAmethyst.opacity(0.18),
                    Color.cosmicVoid
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                HapticFeedbackService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.cosmicSurface))
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Pause.")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Name what's here. Run the protocol. Use the energy.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var footer: some View {
        Text("PAUSE · NAME · ROUTE · USE")
            .font(.system(size: 10, weight: .semibold))
            .tracking(3)
            .foregroundStyle(Color.cosmicTextTertiary)
            .padding(.bottom, 24)
    }

    private var recentChip: AnyView? {
        guard let entry = log.recentEntries(limit: 1).first,
              let delta = entry.moodDelta,
              entry.timestamp > Date().addingTimeInterval(-60 * 60 * 24) else {
            return nil
        }
        return AnyView(
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cosmicAmethyst)
                Text("Last run \(timeAgo(entry.timestamp)) · \(entry.emotion) \(entry.moodBefore) → \(entry.moodAfter ?? entry.moodBefore) (\(delta > 0 ? "−" : "+")\(abs(delta)))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.cosmicTextSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cosmicSurface.opacity(0.7))
            )
        )
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 6) {
            Text("Could not load protocols")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 40)
    }

    private func load() {
        do {
            protocols = try ProtocolLoader.shared.load()
        } catch {
            loadError = String(describing: error)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PauseSessionStarter: Identifiable {
    let id = UUID()
    let proto: PauseProtocol
    let moodBefore: Int
}

private struct EmotionCard: View {
    let proto: PauseProtocol
    let recentCount: Int
    let onPick: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 56, height: 56)
                    Text(proto.emoji)
                        .font(.system(size: 30))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(proto.emotion)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("\(proto.planet) Protocol · \(durationLabel)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(tint)
                }
                Spacer()
                if recentCount >= 3 {
                    Text("\(recentCount)× / 7d")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(tint.opacity(0.2)))
                        .foregroundStyle(tint)
                }
            }

            Text(proto.energyIsFor)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                IntensityChip(label: "rising", value: 35, tint: tint, action: onPick)
                IntensityChip(label: "overflowing", value: 65, tint: tint, action: onPick)
                IntensityChip(label: "drowning", value: 90, tint: tint, action: onPick)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private var durationLabel: String {
        let total = proto.steps.reduce(0) { $0 + max(0, $1.durationSeconds) }
        if total == 0 { return "60–90s" }
        return total < 60 ? "\(total)s" : "\(total / 60)m \(total % 60)s"
    }

    private var tint: Color {
        planetTint(for: proto.planet)
    }
}

private struct IntensityChip: View {
    let label: String
    let value: Int
    let tint: Color
    let action: (Int) -> Void

    var body: some View {
        Button {
            HapticFeedbackService.shared.mediumImpact()
            action(value)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(intensity * 0.35 + 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(intensity * 0.6 + 0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var intensity: Double {
        Double(value) / 100.0
    }
}

func planetTint(for planet: String) -> Color {
    switch planet.lowercased() {
    case "mars":    return Color.planetMars
    case "moon":    return Color.planetMoon
    case "saturn":  return Color.planetSaturn
    case "venus":   return Color.planetVenus
    case "mercury": return Color.planetMercury
    default:        return Color.cosmicAccent
    }
}

#Preview {
    PauseLayerView()
}
