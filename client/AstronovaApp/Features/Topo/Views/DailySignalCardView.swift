import SwiftUI

struct DailySignalCardView: View {
    let card: ArcanaCard
    let isNewCheckIn: Bool
    let streak: Int
    let level: String
    let xp: Int
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            metrics
            logButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.dailySignal.card")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isNewCheckIn ? "sparkles" : "seal.fill")
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(Color.cosmicVoid)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.cosmicGold))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("DAILY SIGNAL")
                        .font(.cosmicMicro)
                        .tracking(1.4)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(isNewCheckIn ? "+15 XP" : "CHECKED IN")
                        .font(.cosmicMicro)
                        .tracking(1.0)
                        .foregroundStyle(Color.cosmicGold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.cosmicGold.opacity(0.12), in: Capsule())
                }

                Text(card.title)
                    .font(.cosmicTitle3)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text(card.subtitle)
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(card.prompt)
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            metric(label: "STREAK", value: "\(streak)d")
            metric(label: "LEVEL", value: level)
            metric(label: "XP", value: "\(xp)")
        }
    }

    private var logButton: some View {
        Button(action: onLog) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                Text("Log today’s signal")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.cosmicCalloutEmphasis)
            .foregroundStyle(Color.cosmicVoid)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cosmicTextPrimary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.dailySignal.logCTA")
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.cosmicMicro)
                .tracking(1.0)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.cosmicSurfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

