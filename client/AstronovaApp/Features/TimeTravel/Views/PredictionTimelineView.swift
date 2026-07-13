import SwiftUI

// MARK: - Data Models

struct MonthlyPrediction: Identifiable, Codable {
    let id: String
    let month: String
    let primaryTheme: String
    let secondaryTheme: String?
    let headline: String
    let doAction: String
    let avoidAction: String
    let triggerSummary: String
    let eventClass: String
    let probabilityBand: String
    let keyDates: [String]
}

struct TimelinePeakWindow: Identifiable {
    let id: String
    let dateRange: String
    let theme: String
    let headline: String?
    let probability: String
}

struct PredictionTimelineData {
    let monthlyPredictions: [MonthlyPrediction]
    let peakWindows: [TimelinePeakWindow]
    let summary: String
}

// MARK: - Event Class Helpers

private enum EventClass: String {
    case capital
    case career
    case relationship
    case relocation
    case health

    var icon: String {
        switch self {
        case .capital: return "chart.line.uptrend.xyaxis"
        case .career: return "briefcase.fill"
        case .relationship: return "heart.fill"
        case .relocation: return "airplane.departure"
        case .health: return "heart.text.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .capital: return .cosmicGold
        case .career: return .cosmicAmethyst
        case .relationship: return .planetVenus
        case .relocation: return .planetJupiter
        case .health: return .planetMars
        }
    }

    var label: String {
        switch self {
        case .capital: return "Capital"
        case .career: return "Career"
        case .relationship: return "Relationship"
        case .relocation: return "Relocation"
        case .health: return "Health"
        }
    }
}

private func probabilityColor(for band: String) -> Color {
    switch band.lowercased() {
    case "high": return .cosmicSuccess
    case "medium-high": return .cosmicGold
    case "medium": return .cosmicWarning
    case "medium-low": return .cosmicTextTertiary
    default: return .cosmicTextTertiary
    }
}

private func probabilityLabel(for band: String) -> String {
    switch band.lowercased() {
    case "high": return "High"
    case "medium-high": return "Med-High"
    case "medium": return "Medium"
    case "medium-low": return "Med-Low"
    default: return band
    }
}

// MARK: - ViewModel

@MainActor
final class PredictionTimelineViewModel: ObservableObject {
    @Published var timelineData: PredictionTimelineData?
    @Published var selectedMonth: MonthlyPrediction?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIServices.shared

    /// Load the prediction timeline from the real API endpoint.
    ///
    /// All parameters are now required — the caller is expected to provide
    /// valid birth data and dasha state (or sensible defaults).
    func loadTimeline(
        startDate: Date,
        endDate: Date,
        birthData: BirthDataRequest?,
        dashaState: DashaStateRequest?,
        userPriors: UserPriorsRequest?
    ) async {
        isLoading = true
        errorMessage = nil

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "yyyy-MM-dd"

        let startStr = dateFmt.string(from: startDate)
        let endStr = dateFmt.string(from: endDate)

        // Fallback birth data if none provided
        let effectiveBirthData: BirthDataRequest
        if let bd = birthData {
            effectiveBirthData = bd
        } else {
            effectiveBirthData = BirthDataRequest(
                date: startStr,
                time: "12:00",
                timezone: "UTC",
                latitude: 0,
                longitude: 0
            )
        }

        // Fallback dasha state
        let effectiveDashaState: DashaStateRequest
        if let ds = dashaState {
            effectiveDashaState = ds
        } else {
            effectiveDashaState = DashaStateRequest(
                mahadashaLord: "jupiter",
                antardashaLord: "mercury",
                mahadashaStart: startStr,
                mahadashaEnd: endStr
            )
        }

        do {
            let response = try await api.fetchPredictionTimeline(
                birthData: effectiveBirthData,
                dashaState: effectiveDashaState,
                startDate: startStr,
                endDate: endStr,
                userPriors: userPriors
            )

            let data = response.toTimelineData()
            timelineData = data
            selectedMonth = data.monthlyPredictions.first

        } catch {
            errorMessage = error.localizedDescription
            // Fall back to sample data when offline or API fails
            if timelineData == nil {
                timelineData = PredictionTimelineData.sample
                selectedMonth = timelineData?.monthlyPredictions.first
            }
        }

        isLoading = false
    }

    func selectMonth(_ prediction: MonthlyPrediction) {
        withAnimation(.cosmicSpring) {
            selectedMonth = prediction
        }
        CosmicHaptics.light()
    }
}

// MARK: - Main View

struct PredictionTimelineView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var viewModel = PredictionTimelineViewModel()
    @State private var selectedDate: Date = Date()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @AppStorage("hasAstronovaPro") private var hasProSubscription = false

    private let embedded: Bool
    private let calendar = Calendar.current
    private let monthSymbols = DateFormatter().shortMonthSymbols ?? []

    init(embedded: Bool = false) {
        self.embedded = embedded
    }

    /// Build a BirthDataRequest from the current profile, or nil if incomplete.
    private var profileBirthDataRequest: BirthDataRequest? {
        let profile = auth.profileManager.profile
        guard let lat = profile.birthLatitude,
              let lon = profile.birthLongitude,
              let tz = profile.timezone else { return nil }

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "yyyy-MM-dd"

        let timeFmt = DateFormatter()
        timeFmt.locale = Locale(identifier: "en_US_POSIX")
        timeFmt.dateFormat = "HH:mm"

        return BirthDataRequest(
            date: dateFmt.string(from: profile.birthDate),
            time: profile.birthTime.map { timeFmt.string(from: $0) } ?? "12:00",
            timezone: tz,
            latitude: lat,
            longitude: lon
        )
    }

    /// Build a DashaStateRequest from cached chart data, or nil.
    private var profileDashaStateRequest: DashaStateRequest? {
        guard let chart = auth.profileManager.lastChart,
              let dashas = chart.vedicChart?.dashas,
              let firstDasha = dashas.first else { return nil }

        let antardashaLord = dashas.count > 1 ? dashas[1].planet : firstDasha.planet

        return DashaStateRequest(
            mahadashaLord: firstDasha.planet,
            antardashaLord: antardashaLord,
            mahadashaStart: firstDasha.startDate,
            mahadashaEnd: firstDasha.endDate
        )
    }

    var body: some View {
        Group {
            if embedded {
                timelineContent
            } else {
                NavigationStack {
                    ScrollView {
                        timelineContent
                    }
                    .background(Color.cosmicBackground)
                    .navigationTitle("Action Forecast")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
        }
        .task {
            await viewModel.loadTimeline(
                startDate: Date(),
                endDate: calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                birthData: profileBirthDataRequest,
                dashaState: profileDashaStateRequest,
                userPriors: nil
            )
        }
        .accessibilityIdentifier("predictionTimelineView")
    }

    private var timelineContent: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            timelineHeader
            monthNavigator
            if let prediction = viewModel.selectedMonth {
                currentMonthCard(prediction)
                    .premiumGate(
                        isPremium: hasProSubscription || !isMonthLocked(prediction),
                        featureName: "Full Forecast",
                        context: .fullTimeline
                    )
            } else if viewModel.isLoading {
                loadingState
            } else if let error = viewModel.errorMessage {
                errorState(error)
            }
            // Peak windows: premium-only
            if hasProSubscription,
               let peaks = viewModel.timelineData?.peakWindows,
               !peaks.isEmpty {
                peakWindowsStrip(peaks)
            } else if !hasProSubscription,
                      viewModel.timelineData?.peakWindows.isEmpty == false {
                // Free user: show a compact CTA instead of the full strip
                TimelineLockBanner()
                    .padding(.horizontal, Cosmic.Spacing.screen)
            }
            if let predictions = viewModel.timelineData?.monthlyPredictions {
                miniCalendarHeatmap(predictions)
                // Show unlock banner after the free months in the heatmap
                if !hasProSubscription {
                    TimelineLockBanner()
                        .padding(.horizontal, Cosmic.Spacing.screen)
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Section 1: Timeline Header

    private var timelineHeader: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Action Forecast")
                        .font(.cosmicTitle1)
                        .tracking(CosmicTypography.Tracking.title)

                    if let summary = viewModel.timelineData?.summary {
                        Text(summary)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Image(systemName: "sparkle.magnifyingglass")
                    .font(.cosmicTitle1)
                    .foregroundStyle(Color.cosmicGold)
                    .cosmicFloat(amount: 3)
            }

            HStack(spacing: Cosmic.Spacing.xxs) {
                Image(systemName: "bolt.fill")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicGold)
                Text("Powered by transit-trigger analysis")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    // MARK: - Section 2: Month Navigator

    private var monthNavigator: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            // Month + Year display with chevrons
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 44, height: 44)
                        .background(Color.cosmicGold.opacity(0.15), in: Circle())
                }
                .accessibilityLabel("Previous month")

                Spacer()

                VStack(spacing: Cosmic.Spacing.xxs) {
                    Text(formattedMonthYear)
                        .font(.cosmicTitle2)
                        .monospacedDigit()

                    if let selected = viewModel.selectedMonth {
                        Text(selected.primaryTheme)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }

                Spacer()

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 44, height: 44)
                        .background(Color.cosmicGold.opacity(0.15), in: Circle())
                }
                .accessibilityLabel("Next month")
            }

            // Year scrubber slider
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                HStack {
                    Text("Year")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Spacer()
                    Text("\(selectedYear)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(selectedYear) },
                        set: { newYear in
                            let year = Int(newYear)
                            selectedYear = year
                            updateSelectedDateForYear(year)
                        }
                    ),
                    in: 2024...2030,
                    step: 1
                )
                .tint(Color.cosmicGold)
            }

            // Month chip row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    ForEach(1...12, id: \.self) { month in
                        let isSelected = calendar.component(.month, from: selectedDate) == month
                        let hasPrediction = viewModel.timelineData?.monthlyPredictions.contains {
                            $0.id == predictionID(for: month)
                        } ?? false

                        Button {
                            selectMonthChip(month)
                        } label: {
                            VStack(spacing: 2) {
                                Text(monthSymbols.indices.contains(month - 1)
                                    ? monthSymbols[month - 1]
                                    : "\(month)")
                                    .font(.cosmicCaptionEmphasis)

                                if hasPrediction {
                                    Circle()
                                        .fill(eventClassColorForMonth(month))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.cosmicGold.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.subtle))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .padding(.horizontal)
    }

    // MARK: - Section 3: Current Month Card

    private func currentMonthCard(_ prediction: MonthlyPrediction) -> some View {
        let eventClass = EventClass(rawValue: prediction.eventClass.lowercased()) ?? .career

        return VStack(spacing: Cosmic.Spacing.sm) {
            // Top: Month + Year
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(prediction.month)
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                Spacer()

                // Event class badge
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Image(systemName: eventClass.icon)
                        .font(.cosmicCaption)
                    Text(eventClass.label)
                        .font(.cosmicCaptionEmphasis)
                }
                .foregroundStyle(eventClass.color)
                .padding(.horizontal, Cosmic.Spacing.sm)
                .padding(.vertical, Cosmic.Spacing.xxs)
                .background(eventClass.color.opacity(0.12), in: Capsule())

                // Probability badge
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Circle()
                        .fill(probabilityColor(for: prediction.probabilityBand))
                        .frame(width: 6, height: 6)
                    Text(probabilityLabel(for: prediction.probabilityBand))
                        .font(.cosmicCaptionEmphasis)
                }
                .foregroundStyle(probabilityColor(for: prediction.probabilityBand))
                .padding(.horizontal, Cosmic.Spacing.xs)
                .padding(.vertical, Cosmic.Spacing.xxs)
                .background(probabilityColor(for: prediction.probabilityBand).opacity(0.12), in: Capsule())
            }

            // Headline
            HStack {
                Text(prediction.headline)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            // Secondary theme if present
            if let secondary = prediction.secondaryTheme {
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Image(systemName: "circle.dotted")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(secondary)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }

            // DO box
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicSuccess)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("DO")
                            .cosmicUppercaseLabel()
                            .foregroundStyle(Color.cosmicSuccess)

                        Text(prediction.doAction)
                            .font(.cosmicCallout)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(Cosmic.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .fill(Color.cosmicSuccess.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .stroke(Color.cosmicSuccess.opacity(0.2), lineWidth: Cosmic.Border.thin)
            )

            // AVOID box
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicError)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("AVOID")
                            .cosmicUppercaseLabel()
                            .foregroundStyle(Color.cosmicError)

                        Text(prediction.avoidAction)
                            .font(.cosmicCallout)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(Cosmic.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .fill(Color.cosmicError.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .stroke(Color.cosmicError.opacity(0.2), lineWidth: Cosmic.Border.thin)
            )

            // Trigger summary row
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
                Text(prediction.triggerSummary)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, Cosmic.Spacing.xs)
            .padding(.vertical, Cosmic.Spacing.xs)
            .background(Color.cosmicGold.opacity(0.06), in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle))

            // Key dates pills
            if !prediction.keyDates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        ForEach(prediction.keyDates, id: \.self) { date in
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.cosmicMicro)
                                Text(date)
                                    .font(.cosmicCaption)
                            }
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .padding(.horizontal, Cosmic.Spacing.sm)
                            .padding(.vertical, Cosmic.Spacing.xxs)
                            .background(Color.cosmicSurfaceSecondary, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(Cosmic.Spacing.screen)
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [eventClass.color, eventClass.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Cosmic.Border.thick
                )
        )
        .cosmicElevation(.medium)
        .padding(.horizontal)
    }

    // MARK: - Section 4: Peak Windows Strip

    private func peakWindowsStrip(_ peaks: [TimelinePeakWindow]) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Peak Windows")
                .font(.cosmicHeadline)
                .padding(.horizontal, Cosmic.Spacing.screen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    ForEach(peaks) { peak in
                        peakWindowCard(peak)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }

    private func peakWindowCard(_ peak: TimelinePeakWindow) -> some View {
        Button {
            if let prediction = viewModel.timelineData?.monthlyPredictions.first(where: {
                peak.dateRange.contains($0.id)
            }) {
                viewModel.selectMonth(prediction)
            }
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                Text(peak.dateRange)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .monospacedDigit()

                Text(peak.theme)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)

                Text(peak.headline ?? "")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)

                HStack(spacing: Cosmic.Spacing.xxs) {
                    Circle()
                        .fill(probabilityColor(for: peak.probability))
                        .frame(width: 6, height: 6)
                    Text(peak.probability.capitalized)
                        .font(.cosmicMicro)
                        .foregroundStyle(probabilityColor(for: peak.probability))
                }
                .padding(.horizontal, Cosmic.Spacing.xs)
                .padding(.vertical, 2)
                .background(probabilityColor(for: peak.probability).opacity(0.12), in: Capsule())
            }
            .padding(Cosmic.Spacing.md)
            .frame(width: 180)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                    .stroke(Color.cosmicTextTertiary.opacity(0.12), lineWidth: Cosmic.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 5: Mini Calendar Heatmap

    private func miniCalendarHeatmap(_ predictions: [MonthlyPrediction]) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("12-Month Outlook")
                    .font(.cosmicHeadline)
                Spacer()
                if !hasProSubscription {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Image(systemName: "lock.fill")
                            .font(.cosmicMicro)
                        Text("3 free")
                            .font(.cosmicMicro)
                    }
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.cosmicGold.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.xxs) {
                    ForEach(predictions) { prediction in
                        let eventClass = EventClass(rawValue: prediction.eventClass)
                        let isSelected = prediction.id == viewModel.selectedMonth?.id
                        let locked = isMonthLocked(prediction)

                        Button {
                            viewModel.selectMonth(prediction)
                        } label: {
                            VStack(spacing: Cosmic.Spacing.xxs) {
                                // Month label with optional lock indicator
                                HStack(spacing: 1) {
                                    if locked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Color.cosmicGold)
                                    }
                                    Text(String(prediction.month.prefix(3)))
                                        .font(.cosmicMicro)
                                        .foregroundStyle(isSelected
                                            ? Color.cosmicTextPrimary
                                            : Color.cosmicTextTertiary)
                                }

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(eventClass?.color ?? Color.cosmicTextTertiary)
                                    .opacity(locked ? 0.35 : 1.0)
                                    .frame(width: 32, height: isSelected ? 42 : 32)

                                Circle()
                                    .fill(probabilityColor(for: prediction.probabilityBand))
                                    .opacity(locked ? 0.35 : 1.0)
                                    .frame(width: 4, height: 4)
                            }
                            .padding(.vertical, Cosmic.Spacing.xxs)
                            .padding(.horizontal, 4)
                            .background(
                                isSelected
                                    ? Color.cosmicGold.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }

    // MARK: - Loading & Error States

    private var loadingState: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            CosmicLoadingView(style: .constellation)
            Text("Mapping transits...")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Cosmic.Spacing.xxl)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicWarning)

            Text("Unable to Load Forecast")
                .font(.cosmicHeadline)

            Text(message)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Premium Gating Helpers

    /// The set of month IDs (format "YYYY-MM") that are free for all users.
    /// Covers the current month + next 2 months (total of 3).
    private var freeMonthIDs: Set<String> {
        let today = Date()
        let calendar = Calendar.current

        var ids: Set<String> = []
        for offset in 0..<3 {
            guard let date = calendar.date(byAdding: .month, value: offset, to: today) else { continue }
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            ids.insert(String(format: "%d-%02d", year, month))
        }
        return ids
    }

    /// Whether a given monthly prediction is locked behind the premium gate.
    private func isMonthLocked(_ prediction: MonthlyPrediction) -> Bool {
        !hasProSubscription && !freeMonthIDs.contains(prediction.id)
    }

    /// Whether the currently selected month is premium-gated.
    private var isCurrentMonthLocked: Bool {
        guard let selected = viewModel.selectedMonth else { return false }
        return isMonthLocked(selected)
    }

    private func shiftMonth(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: offset, to: selectedDate) else { return }
        withAnimation(.cosmicSpring) {
            selectedDate = newDate
        }
        selectedYear = calendar.component(.year, from: newDate)
        selectPredictionForDate(newDate)
        CosmicAudio.shared.selection()
    }

    private func selectMonthChip(_ month: Int) {
        updateSelectedDate(month: month)
        selectPredictionForDate(selectedDate)
        CosmicAudio.shared.lightTap()
    }

    private func updateSelectedDateForYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.year = year
        if let newDate = calendar.date(from: components) {
            withAnimation(.cosmicSpring) {
                selectedDate = newDate
            }
            selectPredictionForDate(newDate)
        }
    }

    private func updateSelectedDate(month: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.month = month
        if let firstOfMonth = calendar.date(from: DateComponents(year: components.year, month: month, day: 1)),
           let range = calendar.range(of: .day, in: .month, for: firstOfMonth) {
            let lastDay = range.upperBound - 1
            components.day = min(max(components.day ?? 1, range.lowerBound), lastDay)
        }
        if let newDate = calendar.date(from: components) {
            withAnimation(.cosmicSpring) {
                selectedDate = newDate
            }
        }
    }

    private func predictionID(for month: Int) -> String {
        let year = selectedYear
        return String(format: "%d-%02d", year, month)
    }

    private func selectPredictionForDate(_ date: Date) {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let id = String(format: "%d-%02d", year, month)
        if let prediction = viewModel.timelineData?.monthlyPredictions.first(where: { $0.id == id }) {
            viewModel.selectMonth(prediction)
        }
    }

    private func eventClassColorForMonth(_ month: Int) -> Color {
        let id = predictionID(for: month)
        guard let prediction = viewModel.timelineData?.monthlyPredictions.first(where: { $0.id == id }),
              let eventClass = EventClass(rawValue: prediction.eventClass) else {
            return Color.clear
        }
        return eventClass.color
    }
}

// MARK: - Sample Data

extension PredictionTimelineData {
    static let sample = PredictionTimelineData(
        monthlyPredictions: [
            MonthlyPrediction(
                id: "2026-06",
                month: "June 2026",
                primaryTheme: "Capital Initialization",
                secondaryTheme: "Hidden Research",
                headline: "Jupiter activates your 8th house capital pipeline while Saturn stabilizes earned income",
                doAction: "Prepare institutional data room. Close Visusta retainer contract before Jupiter-Mars aspect Oct 14.",
                avoidAction: "Do not start new R&D without revenue anchor. Defer uncommitted hires until Aug.",
                triggerSummary: "Jupiter enters Cancer Jun 2, aspects natal Mars Oct 14",
                eventClass: "capital",
                probabilityBand: "high",
                keyDates: ["Jun 2: Jupiter → Cancer", "Jun 15: Sun trine natal Jupiter", "Oct 14: Jupiter △ natal Mars"]
            ),
            MonthlyPrediction(
                id: "2026-07",
                month: "July 2026",
                primaryTheme: "Velocity Surge",
                secondaryTheme: "Contract Acceleration",
                headline: "Mars conjoins your midheaven while Mercury stations direct in Leo",
                doAction: "Ship the enterprise PoC. Book Q3 review with anchor clients. Push signed deals through legal.",
                avoidAction: "Do not chase speculative partnerships. Avoid multi-year commitments without exit clause.",
                triggerSummary: "Mars conjunct MC Jul 8, Mercury direct Jul 22",
                eventClass: "career",
                probabilityBand: "medium-high",
                keyDates: ["Jul 8: Mars σ MC", "Jul 22: Mercury direct"]
            ),
            MonthlyPrediction(
                id: "2026-08",
                month: "August 2026",
                primaryTheme: "Revenue Lock-In",
                secondaryTheme: "Dubai Base",
                headline: "Venus trines your 2nd house ruler. Income streams crystallize.",
                doAction: "Deploy Dubai operations base. Finalize team compensation structure. Invoice Q3 retainers.",
                avoidAction: "Do not delay collections. Avoid team expansion without signed revenue.",
                triggerSummary: "Venus trine 2nd ruler Aug 5, Full Moon in Aquarius Aug 19",
                eventClass: "capital",
                probabilityBand: "high",
                keyDates: ["Aug 5: Venus △ 2H ruler", "Aug 19: Full Moon · Aquarius"]
            ),
            MonthlyPrediction(
                id: "2026-09",
                month: "September 2026",
                primaryTheme: "Network Expansion",
                secondaryTheme: nil,
                headline: "Rahu transit highlights your 11th house of networks and strategic alliances",
                doAction: "Attend industry summit. Close 2 warm introductions. Publish thought leadership on capital markets.",
                avoidAction: "Do not spread attention across more than 3 prospects. Avoid public pricing discussions.",
                triggerSummary: "Rahu in 11H, Mercury retrograde shadow Sep 8",
                eventClass: "career",
                probabilityBand: "medium",
                keyDates: ["Sep 8: Mercury shadow", "Sep 21: Sun enters Virgo"]
            ),
            MonthlyPrediction(
                id: "2026-10",
                month: "October 2026",
                primaryTheme: "Institutional Validation",
                secondaryTheme: "Legacy Architecture",
                headline: "Jupiter exactly aspects natal Mars. Institutional credibility peaks.",
                doAction: "Publish case study with anchor client. Apply for regulated entity status. Onboard compliance counsel.",
                avoidAction: "Do not cut corners on KYC/AML infrastructure. Avoid unverified counterparties.",
                triggerSummary: "Jupiter △ natal Mars exact Oct 14, Mercury retrograde Oct 22",
                eventClass: "capital",
                probabilityBand: "high",
                keyDates: ["Oct 14: Jupiter △ natal Mars", "Oct 22: Mercury retrograde"]
            ),
            MonthlyPrediction(
                id: "2026-11",
                month: "November 2026",
                primaryTheme: "Review & Recalibrate",
                secondaryTheme: nil,
                headline: "Mercury retrograde in Scorpio. Audit positioning. Fix leaks.",
                doAction: "Run full portfolio review. Consolidate vendor contracts. Stress-test cash runway through 2027.",
                avoidAction: "Do not launch new product. Avoid irreversible structural changes.",
                triggerSummary: "Mercury retrograde Oct 22 – Nov 12, Mars enters Sagittarius",
                eventClass: "capital",
                probabilityBand: "medium-low",
                keyDates: ["Nov 12: Mercury direct", "Nov 25: Mars → Sagittarius"]
            ),
            MonthlyPrediction(
                id: "2026-12",
                month: "December 2026",
                primaryTheme: "Relationship Reckoning",
                secondaryTheme: "Year-End Clarity",
                headline: "Venus-Saturn conjunction in your 7th house tests partnership foundations",
                doAction: "Have the hard conversation with co-founders. Document equity, roles, and exit clauses.",
                avoidAction: "Do not sign partnership agreements before Jan 2027. Avoid emotional ultimatums.",
                triggerSummary: "Venus conjunct Saturn in 7H Dec 18",
                eventClass: "relationship",
                probabilityBand: "medium-high",
                keyDates: ["Dec 12: New Moon · Sagittarius", "Dec 18: Venus σ Saturn"]
            ),
            MonthlyPrediction(
                id: "2027-01",
                month: "January 2027",
                primaryTheme: "Geographic Pivot",
                secondaryTheme: nil,
                headline: "Rahu return in your 4th house triggers relocation questions. Jupiter supports international moves.",
                doAction: "Scout Singapore and Zurich as secondary bases. File visa applications. Set up local entity structure.",
                avoidAction: "Do not commit to primary residence relocation without 90-day trial period.",
                triggerSummary: "Rahu return in 4H, Jupiter trine 9H ruler",
                eventClass: "relocation",
                probabilityBand: "high",
                keyDates: ["Jan 3: Venus enters Aquarius", "Jan 28: Mercury trine Uranus"]
            ),
            MonthlyPrediction(
                id: "2027-02",
                month: "February 2027",
                primaryTheme: "Health & Vitality",
                secondaryTheme: "Team Building",
                headline: "Mars in your 6th house. Physical energy peaks. Health routines need structure.",
                doAction: "Start executive health protocol. Hire chief of staff to offload operations. Establish weekly review cadence.",
                avoidAction: "Do not ignore sleep or recovery signals. Avoid 60+ hour weeks for more than 2 weeks straight.",
                triggerSummary: "Mars in 6H, Sun enters Pisces Feb 18",
                eventClass: "health",
                probabilityBand: "medium",
                keyDates: ["Feb 3: Mars sextile Saturn", "Feb 18: Sun → Pisces"]
            ),
            MonthlyPrediction(
                id: "2027-03",
                month: "March 2027",
                primaryTheme: "Career Pinnacle",
                secondaryTheme: "Public Recognition",
                headline: "Sun conjoins your MC while Jupiter trines your 10th house lord",
                doAction: "Launch public-facing initiative. Accept keynote invitation. Publish annual outlook report.",
                avoidAction: "Do not deflect recognition. Avoid speaking on behalf of the company without prepared remarks.",
                triggerSummary: "Sun conjunct MC Mar 14, Jupiter trine 10H lord",
                eventClass: "career",
                probabilityBand: "high",
                keyDates: ["Mar 14: Sun σ MC", "Mar 20: Spring Equinox"]
            ),
            MonthlyPrediction(
                id: "2027-04",
                month: "April 2027",
                primaryTheme: "Legacy Infrastructure",
                secondaryTheme: "IP Protection",
                headline: "Saturn stations direct in your 10th house. Build durable systems.",
                doAction: "Finalize IP portfolio. Establish board advisory panel. Architect scalable compliance framework.",
                avoidAction: "Do not launch without QA. Avoid shipping features without documentation.",
                triggerSummary: "Saturn direct in 10H Apr 8, Mercury enters Taurus",
                eventClass: "career",
                probabilityBand: "medium-high",
                keyDates: ["Apr 8: Saturn direct", "Apr 22: Mercury → Taurus"]
            ),
            MonthlyPrediction(
                id: "2027-05",
                month: "May 2027",
                primaryTheme: "Synthesis & Harvest",
                secondaryTheme: nil,
                headline: "Jupiter trine Saturn. Growth meets structure. 12-month cycle completes.",
                doAction: "Close enterprise PoC before Jupiter-Mars aspect. Publish annual review. Set 2028 targets.",
                avoidAction: "Do not abandon current revenue for speculative new verticals. Avoid unforced restructures.",
                triggerSummary: "Jupiter trine Saturn May 19, Venus enters Gemini",
                eventClass: "capital",
                probabilityBand: "medium-high",
                keyDates: ["May 1: Mars sextile Jupiter", "May 19: Jupiter △ Saturn"]
            )
        ],
        peakWindows: [
            TimelinePeakWindow(
                id: "peak-1",
                dateRange: "Jun – Aug 2026",
                theme: "Capital Surge",
                headline: "Three-month Jupiter activation of your wealth axis",
                probability: "high"
            ),
            TimelinePeakWindow(
                id: "peak-2",
                dateRange: "Oct 2026",
                theme: "Institutional Peak",
                headline: "Jupiter-Mars exact aspect: credibility event",
                probability: "high"
            ),
            TimelinePeakWindow(
                id: "peak-3",
                dateRange: "Dec 2026",
                theme: "Partnership Test",
                headline: "Venus-Saturn conjunction tests alignment",
                probability: "medium-high"
            ),
            TimelinePeakWindow(
                id: "peak-4",
                dateRange: "Jan 2027",
                theme: "Relocation Window",
                headline: "Rahu return activates geographic pivot",
                probability: "high"
            ),
            TimelinePeakWindow(
                id: "peak-5",
                dateRange: "Mar 2027",
                theme: "Career Pinnacle",
                headline: "Sun-MC conjunction: visibility peak",
                probability: "high"
            ),
            TimelinePeakWindow(
                id: "peak-6",
                dateRange: "May 2027",
                theme: "Harvest",
                headline: "Jupiter-Saturn trine: structural completion",
                probability: "medium-high"
            )
        ],
        summary: "12-month transit-trigger forecast based on your natal chart and current dashas. Each month maps concrete actions to planetary triggers."
    )
}

// MARK: - Preview

#Preview("Prediction Timeline") {
    PredictionTimelineView()
        .environmentObject(AuthState())
        .preferredColorScheme(.dark)
}
