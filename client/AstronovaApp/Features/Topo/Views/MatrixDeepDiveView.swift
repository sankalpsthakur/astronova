import SwiftUI

// MARK: - Matrix Deep Dive

struct MatrixDeepDiveView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var loshuData: LoshuData = .sample
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    header
                    liveStatusCard
                    LoshuGridView(data: loshuData, embedded: true)
                    eigenvalueCards
                    transformationCards
                }
                .padding(.vertical, Cosmic.Spacing.lg)
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .task { await loadNumerologyReport() }
        .accessibilityIdentifier("matrixDeepDiveView")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Matrix")
                        .font(.cosmicDisplay)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Loshu calculations, eigenvalues, and transformation functions.")
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "square.grid.3x3.fill")
                    .font(.cosmicTitle1)
                    .foregroundStyle(Color.cosmicGold)
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private var liveStatusCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "function")
                .font(.cosmicTitle3)
                .foregroundStyle(errorMessage == nil ? Color.cosmicAccent : Color.cosmicWarning)

            VStack(alignment: .leading, spacing: 5) {
                Text(errorMessage == nil ? "Live numerology report" : "Cached numerology fallback")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(errorMessage ?? "Server report loaded from date of birth and phone-vector sum.")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if isLoading {
                ProgressView()
                    .tint(Color.cosmicGold)
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicAccent.opacity(0.14), lineWidth: 0.5)
        )
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private var eigenvalueCards: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            sectionHeader(
                title: "Eigenvalues",
                subtitle: "Dominant signal strengths from the personalized 3x3 matrix."
            )

            VStack(spacing: 10) {
                ForEach(Array(displayEigenvalues.enumerated()), id: \.offset) { index, value in
                    HStack(spacing: 12) {
                        Text("lambda \(index + 1)")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .tracking(0.8)
                            .frame(width: 72, alignment: .leading)

                        ProgressView(value: normalizedEigenvalue(value))
                            .tint(eigenvalueTint(index))

                        Text(String(format: "%.2f", value))
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .monospacedDigit()
                            .frame(width: 52, alignment: .trailing)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurfaceSecondary))
                }
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.18), lineWidth: 0.5)
        )
        .padding(.horizontal, Cosmic.Spacing.screen)
        .accessibilityIdentifier("matrix.eigenvalues")
    }

    private var transformationCards: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            sectionHeader(
                title: "Transformations",
                subtitle: "Actions derived from missing digits, incomplete planes, and eigenvalue shape."
            )

            LazyVStack(spacing: 10) {
                ForEach(transformationFunctions) { transform in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: transform.icon)
                            .font(.cosmicCallout)
                            .foregroundStyle(transform.tint)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(transform.tint.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(transform.title)
                                .font(.cosmicCalloutEmphasis)
                                .foregroundStyle(Color.cosmicTextPrimary)
                            Text(transform.body)
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurfaceSecondary))
                }
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicAccent.opacity(0.14), lineWidth: 0.5)
        )
        .padding(.horizontal, Cosmic.Spacing.screen)
        .accessibilityIdentifier("matrix.transformations")
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(subtitle)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var displayEigenvalues: [Double] {
        let values = loshuData.eigenvalues.isEmpty ? LoshuData.sample.eigenvalues : loshuData.eigenvalues
        return Array(values.prefix(3))
    }

    private func normalizedEigenvalue(_ value: Double) -> Double {
        let maxValue = max(displayEigenvalues.map(abs).max() ?? 1, 1)
        return min(max(abs(value) / maxValue, 0), 1)
    }

    private func eigenvalueTint(_ index: Int) -> Color {
        switch index {
        case 0: return .cosmicGold
        case 1: return .cosmicAmethyst
        default: return .cosmicAccent
        }
    }

    private var transformationFunctions: [MatrixTransformation] {
        var transforms: [MatrixTransformation] = []

        if !loshuData.missing.isEmpty {
            transforms.append(MatrixTransformation(
                id: "missing-digits",
                title: "Rebuild missing digits \(loshuData.missing.map(String.init).joined(separator: ", "))",
                body: missingDigitAction(for: loshuData.missing),
                icon: "plus.square.on.square",
                tint: .cosmicGold
            ))
        }

        if let plane = loshuData.completedPlanes.first(where: { !$0.isComplete }) {
            transforms.append(MatrixTransformation(
                id: "plane-\(plane.name)",
                title: "Complete \(plane.name)",
                body: "Treat \(plane.numbers.map(String.init).joined(separator: "-")) as a weekly behavior loop: one cue, one action, one review.",
                icon: "rectangle.3.group",
                tint: .cosmicAmethyst
            ))
        }

        if let firstEigenvalue = displayEigenvalues.first {
            transforms.append(MatrixTransformation(
                id: "eigenvalue-dominance",
                title: "Stabilize the dominant eigenvalue",
                body: firstEigenvalue >= 10
                    ? "High dominant signal: choose fewer priorities and protect recovery so intensity does not become volatility."
                    : "Distributed signal: create one visible scoreboard so scattered effort becomes directional progress.",
                icon: "waveform.path.ecg.rectangle",
                tint: .cosmicAccent
            ))
        }

        transforms.append(MatrixTransformation(
            id: "driver-conductor",
            title: "Driver \(loshuData.driverNumber), conductor \(loshuData.conductorNumber)",
            body: "Use the driver as the first move and the conductor as the finish condition before committing to a decision.",
            icon: "arrow.triangle.branch",
            tint: .cosmicSuccess
        ))

        return transforms
    }

    private func missingDigitAction(for digits: [Int]) -> String {
        let names = digits.prefix(3).map { digitName($0) }.joined(separator: ", ")
        return "Prioritize \(names) with one concrete practice each: schedule it, measure it, and review it before the next forecast window."
    }

    private func digitName(_ digit: Int) -> String {
        switch digit {
        case 1: return "self-direction"
        case 2: return "emotional sensing"
        case 3: return "expression"
        case 4: return "structure"
        case 5: return "adaptability"
        case 6: return "responsibility"
        case 7: return "depth"
        case 8: return "discipline"
        case 9: return "vision"
        default: return "integration"
        }
    }

    @MainActor
    private func loadNumerologyReport() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIServices.shared.fetchNumerologyReport(
                dob: Self.birthDateFormatter.string(from: auth.profileManager.profile.birthDate),
                phoneDigitSum: UserPriorsRequest.storedPhoneDigitSum()
            )
            loshuData = response.toLoshuData()
        } catch {
            errorMessage = "Unable to refresh the server report. Showing the last known matrix."
        }

        isLoading = false
    }

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct MatrixTransformation: Identifiable {
    let id: String
    let title: String
    let body: String
    let icon: String
    let tint: Color
}

#Preview("Matrix Deep Dive") {
    MatrixDeepDiveView()
        .environmentObject(AuthState())
        .preferredColorScheme(.dark)
}
