import SwiftUI

// MARK: - Timeline Tab

struct TimelineTabView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var mirrorViewModel = CosmicMirrorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    header
                    systemOverviewSection
                    dashaPulseSection
                    PredictionTimelineView(embedded: true)
                }
                .padding(.vertical, Cosmic.Spacing.lg)
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .task {
            await mirrorViewModel.loadMirror(
                profile: auth.profileManager.profile,
                chart: auth.profileManager.lastChart
            )
        }
        .accessibilityIdentifier("timelineTabView")
    }

    private var mirrorData: CosmicMirrorData {
        mirrorViewModel.mirrorData ?? .sample
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Timeline")
                        .font(.cosmicDisplay)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Server state, dasha pulse, and forecast sequence.")
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                liveBadge
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private var liveBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mirrorViewModel.errorMessage == nil ? Color.cosmicSuccess : Color.cosmicWarning)
                .frame(width: 7, height: 7)
            Text(mirrorViewModel.errorMessage == nil ? "LIVE" : "CACHED")
                .font(.cosmicMicro)
                .fontWeight(.semibold)
                .tracking(0.8)
        }
        .foregroundStyle(Color.cosmicTextPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.cosmicSurface))
        .overlay(Capsule().stroke(Color.cosmicAccent.opacity(0.14), lineWidth: 0.5))
    }

    private var systemOverviewSection: some View {
        let data = mirrorData
        let archetype = data.archetype
        let matrixCount = data.matrixEntries?.count ?? 0
        let constraintCount = data.constraints?.count ?? 0
        let missingCount = data.loshu?.missing.count ?? 0

        return VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Overview")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(archetype?.primary ?? "Live synthesis")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicGold)
                }

                Spacer(minLength: 0)

                Image(systemName: "server.rack")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicAccent)
            }

            Text(data.synthesisNarrative ?? "Astronova is aligning your chart, numerology, dashas, and prediction windows into one current operating picture.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                metricCard(label: "MATRIX", value: "\(matrixCount)")
                metricCard(label: "GUARDS", value: "\(constraintCount)")
                metricCard(label: "LOSHU", value: "\(missingCount) gaps")
            }

            if mirrorViewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color.cosmicGold)
                    Text("Refreshing live mirror")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            } else if let message = mirrorViewModel.errorMessage {
                Text(message)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicWarning)
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicAccent.opacity(0.14), lineWidth: 0.5)
        )
        .padding(.horizontal, Cosmic.Spacing.screen)
        .accessibilityIdentifier("timeline.systemOverview")
    }

    private var dashaPulseSection: some View {
        let pulse = mirrorData.dashaPulse ?? .sample
        let progress = max(0, min(1, Double(pulse.currentYear) / Double(max(pulse.totalYears, 1))))

        return VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dasha Pulse")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("\(pulse.currentPlanet.capitalized) year \(pulse.currentYear) of \(pulse.totalYears)")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer(minLength: 0)

                Text("\(Int(progress * 100))%")
                    .font(.cosmicTitle3)
                    .foregroundStyle(Color.cosmicGold)
                    .monospacedDigit()
            }

            ProgressView(value: progress)
                .tint(Color.cosmicGold)
                .accessibilityLabel("Dasha progress \(Int(progress * 100)) percent")

            HStack(spacing: 10) {
                dashaDateCard(label: "START", date: pulse.startDate)
                dashaDateCard(label: "END", date: pulse.endDate)
            }

            if let transition = pulse.nextTransitionLabel {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next transition")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .tracking(0.9)
                        Text(transitionDateLabel(transition, date: pulse.nextTransitionDate))
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurfaceSecondary))
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.18), lineWidth: 0.5)
        )
        .padding(.horizontal, Cosmic.Spacing.screen)
        .accessibilityIdentifier("timeline.dashaPulse")
    }

    private func metricCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
                .tracking(0.8)
            Text(value)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.cosmicVoid.opacity(0.28)))
    }

    private func dashaDateCard(label: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
                .tracking(0.8)
            Text(Self.dashaDateFormatter.string(from: date))
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.cosmicSurfaceSecondary))
    }

    private func transitionDateLabel(_ title: String, date: Date?) -> String {
        guard let date else { return title }
        return "\(title) - \(Self.dashaDateFormatter.string(from: date))"
    }

    private static let dashaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

#Preview("Timeline Tab") {
    TimelineTabView()
        .environmentObject(AuthState())
        .preferredColorScheme(.dark)
}
