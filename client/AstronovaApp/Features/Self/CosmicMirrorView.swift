import SwiftUI

// MARK: - Cosmic Mirror Data Models

/// Unified dashboard payload from the synthesis API endpoint.
struct CosmicMirrorData: Codable {
    // From rajayoga service
    let archetype: ChartArchetype?
    let matrixEntries: [PlanetMatrixEntry]?
    let constraints: [ChartConstraint]?

    // From numerology service
    let loshu: LoshuData?

    // From prediction service
    let currentMonthPrediction: MonthPrediction?
    let peakWindows: [MirrorPeakWindow]?

    // From existing services
    let dashaPulse: DashaPulseData?
    let journeyProgress: JourneyProgressData?

    // Synthesis
    let synthesisNarrative: String?
}

// MARK: - Month Prediction

struct MonthPrediction: Codable, Identifiable {
    let id: String
    let month: String
    let headline: String
    let doAction: String
    let avoidAction: String
    let transitTriggers: [String]
}

// MARK: - Peak Window

struct MirrorPeakWindow: Codable, Identifiable {
    let id: String
    let dateRange: String
    let theme: String
    let headline: String?
    let probability: String
}

// MARK: - Dasha Pulse Data

/// Lightweight dasha snapshot for the mirror — wraps
/// the existing DashaInfo with next-transition context.
struct DashaPulseData: Codable {
    let currentPlanet: String
    let currentYear: Int
    let totalYears: Int
    let startDate: Date
    let endDate: Date
    let nextTransitionLabel: String?
    let nextTransitionDate: Date?

    var asDashaInfo: DashaInfo {
        DashaInfo(
            planet: currentPlanet,
            startDate: startDate,
            endDate: endDate,
            currentYear: currentYear,
            totalYears: totalYears
        )
    }
}

// MARK: - Journey Progress Data

/// Gamification snapshot for the mirror card.
struct JourneyProgressData: Codable {
    let levelTitle: String
    let streak: Int
    let completedMilestoneCount: Int
    let totalMilestones: Int
}

// MARK: - ViewModel

@MainActor
final class CosmicMirrorViewModel: ObservableObject {
    @Published var mirrorData: CosmicMirrorData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let synthesisService = SynthesisService.shared

    /// Load the Cosmic Mirror from the real synthesis API endpoint.
    ///
    /// Accepts the profile and optional chart so the view can forward
    /// whatever data `AuthState` / `UserProfileManager` currently holds.
    func loadMirror(
        profile: UserProfile,
        chart: ChartResponse? = nil,
        dashaState: DashaStateRequest? = nil,
        userPriors: UserPriorsRequest? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        await synthesisService.loadMirror(
            profile: profile,
            chart: chart,
            dashaState: dashaState,
            userPriors: userPriors
        )

        // Mirror the service state into the view model
        mirrorData = synthesisService.mirrorData
        errorMessage = synthesisService.errorMessage
        isLoading = false
    }
}

// MARK: - Cosmic Mirror View

/// The unified Self tab dashboard — a single scrollable "Cosmic Mirror"
/// that shows the user exactly who they are and what to do.
struct CosmicMirrorView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @StateObject private var viewModel = CosmicMirrorViewModel()

    @State private var sectionsVisible = false
    @State private var activeSheet: SheetDestination?
    @AppStorage("hasAstronovaPro") private var hasProSubscription = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile {
        auth.profileManager.profile
    }

    private var completeness: ProfileCompleteness {
        ProfileCompleteness(profile: profile)
    }

    private var canFetchData: Bool {
        completeness.canCalculateDasha
    }

    private enum SheetDestination: Identifiable {
        case birthEdit
        case settings
        case paywall
        case dashaDetail
        case journeyMap
        case reportShop
        case reportsLibrary

        var id: String {
            switch self {
            case .birthEdit: return "birthEdit"
            case .settings: return "settings"
            case .paywall: return "paywall"
            case .dashaDetail: return "dashaDetail"
            case .journeyMap: return "journeyMap"
            case .reportShop: return "reportShop"
            case .reportsLibrary: return "reportsLibrary"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            cosmicBackground

            if viewModel.isLoading && viewModel.mirrorData == nil {
                loadingShimmer
            } else if let error = viewModel.errorMessage, viewModel.mirrorData == nil {
                errorState(message: error)
            } else if let data = viewModel.mirrorData {
                mainScrollView(data: data)
            } else if !auth.isAuthenticated {
                emptyState
            } else {
                // Transitional: no data yet, not loading
                loadingShimmer
            }
        }
        .task {
            if canFetchData {
                await viewModel.loadMirror(
                    profile: profile,
                    chart: auth.profileManager.lastChart
                )
            }
        }
        .onChange(of: completeness.level) { oldLevel, newLevel in
            if newLevel.rawValue > oldLevel.rawValue && canFetchData {
                Task {
                    await viewModel.loadMirror(
                        profile: profile,
                        chart: auth.profileManager.lastChart
                    )
                }
            }
        }
        .onChange(of: profile.birthDate) { _, _ in
            if canFetchData {
                Task {
                    await viewModel.loadMirror(
                        profile: profile,
                        chart: auth.profileManager.lastChart
                    )
                }
            }
        }
        .accessibilityIdentifier("cosmicMirrorView")
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .birthEdit:
                QuickBirthEditView()
                    .environmentObject(auth)
            case .settings:
                MoreOptionsSheet(bookmarks: .constant([]))
                    .environmentObject(auth)
            case .paywall:
                PaywallVariantRouter()
            case .dashaDetail:
                NavigationStack {
                    EnhancedTimeTravelView()
                        .environmentObject(auth)
                }
            case .journeyMap:
                NavigationStack {
                    JourneyMapSheet()
                        .environmentObject(gamification)
                }
            case .reportShop:
                InlineReportsStoreSheet()
                    .environmentObject(auth)
            case .reportsLibrary:
                ReportsLibraryView(reports: [])
            }
        }
    }

    // MARK: - Background

    private var cosmicBackground: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.cosmicVoid,
                    Color.cosmicCosmos.opacity(0.5),
                    Color.cosmicAmethyst.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !reduceMotion {
                CosmicParticleField()
                    .opacity(0.6)
            }
        }
    }

    // MARK: - Loading Shimmer

    private var loadingShimmer: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.lg) {
                nameHeader
                    .padding(.top, Cosmic.Spacing.lg)

                ForEach(0..<5, id: \.self) { index in
                    shimmerCard(height: index == 0 ? 260 : index == 1 ? 280 : 160)
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
        .disabled(true)
    }

    private func shimmerCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
            .fill(Color.cosmicSurface)
            .frame(height: height)
            .cosmicShimmer(isActive: true)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: Cosmic.Spacing.xl) {
            Spacer()

            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundStyle(Color.cosmicTextTertiary)

            Text(message)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Cosmic.Spacing.xl)

            Button {
                Task {
                    await viewModel.loadMirror(
                        profile: profile,
                        chart: auth.profileManager.lastChart
                    )
                }
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(Color.cosmicGold)
                .padding(.horizontal, Cosmic.Spacing.lg)
                .padding(.vertical, Cosmic.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicGold.opacity(0.3), lineWidth: Cosmic.Border.thin)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Cosmic.Spacing.xl) {
            Spacer()

            CosmicLoadingView(style: .constellation)
                .scaleEffect(1.5)

            VStack(spacing: Cosmic.Spacing.sm) {
                Text("Cosmic Mirror Awaits")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Sign in to reveal your archetype, planetary matrix, and personalized cosmic guidance.")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Main Scroll View

    private func mainScrollView(data: CosmicMirrorData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Cosmic.Spacing.xl) {
                nameHeader
                    .padding(.top, Cosmic.Spacing.lg)

                // 1. Archetype Header
                if let archetype = data.archetype {
                    ArchetypeHeaderView(archetype: archetype)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 0), value: sectionsVisible)
                }

                // 2. Now/Next — Dasha Pulse
                if let pulse = data.dashaPulse {
                    dashaPulseSection(pulse)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 1), value: sectionsVisible)
                } else if canFetchData {
                    fallbackDashaSection
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 1), value: sectionsVisible)
                }

                // 3. Optimization Matrix
                if let entries = data.matrixEntries, !entries.isEmpty {
                    PlanetaryMatrixView(entries: entries)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 2), value: sectionsVisible)
                }

                // 4. Loshu Grid
                if let loshu = data.loshu {
                    LoshuGridView(data: loshu)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 3), value: sectionsVisible)
                }

                // 5. This Month Card
                if let monthPred = data.currentMonthPrediction {
                    thisMonthCard(monthPred)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 4), value: sectionsVisible)
                }

                // 6. Peak Windows
                if let windows = data.peakWindows, !windows.isEmpty {
                    peakWindowsSection(windows, isPremium: hasProSubscription)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 5), value: sectionsVisible)
                }

                // 7. Constraints
                if let constraints = data.constraints {
                    constraintSection(constraints)
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 6), value: sectionsVisible)
                }

                // 8. Synthesis Narrative (Premium-gated)
                if let narrative = data.synthesisNarrative {
                    synthesisCard(narrative)
                        .premiumGate(
                            isPremium: hasProSubscription,
                            featureName: "Cosmic Synthesis",
                            context: .synthesisNarrative
                        )
                        .opacity(sectionsVisible ? 1 : 0)
                        .offset(y: sectionsVisible ? 0 : 24)
                        .animation(.cosmicStaggered(index: 7), value: sectionsVisible)
                }

                // 9. Journey Map
                journeyMapCard
                    .opacity(sectionsVisible ? 1 : 0)
                    .offset(y: sectionsVisible ? 0 : 24)
                    .animation(.cosmicStaggered(index: 8), value: sectionsVisible)

                // 10. Reports Link
                reportsSection
                    .opacity(sectionsVisible ? 1 : 0)
                    .offset(y: sectionsVisible ? 0 : 24)
                    .animation(.cosmicStaggered(index: 9), value: sectionsVisible)

                // Account footer
                accountFooter
                    .opacity(sectionsVisible ? 1 : 0)
                    .animation(.cosmicStaggered(index: 10), value: sectionsVisible)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
        .refreshable {
            await viewModel.loadMirror(
                profile: profile,
                chart: auth.profileManager.lastChart
            )
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.05)) {
                    sectionsVisible = true
                }
            } else {
                sectionsVisible = true
            }
        }
    }

    // MARK: - Name Header

    private var nameHeader: some View {
        HStack {
            Text(profile.fullName.isEmpty ? "Cosmic Traveler" : profile.fullName)
                .font(.cosmicTitle1)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            // Settings gear
            Button {
                CosmicHaptics.medium()
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)
                    .frame(width: 38, height: 38)
                    .background(Color.cosmicGold.opacity(0.12), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.cosmicGold.opacity(0.16), lineWidth: Cosmic.Border.hairline)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Section 2: Dasha Pulse

    private func dashaPulseSection(_ pulse: DashaPulseData) -> some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            CosmicPulseView(
                currentDasha: pulse.asDashaInfo,
                accuracyLevel: completeness.level,
                onTap: { activeSheet = .dashaDetail }
            )

            if let nextLabel = pulse.nextTransitionLabel,
               let nextDate = pulse.nextTransitionDate {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.cosmicAmethyst)
                    Text("Next: \(nextLabel)")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text("·")
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(nextTransitionDateFormatted(from: nextDate))
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicAmethyst)
                }
                .padding(.horizontal, Cosmic.Spacing.md)
                .padding(.vertical, Cosmic.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                        .fill(Color.cosmicAmethyst.opacity(0.08))
                )
                .accessibilityLabel("Next dasha transition: \(nextLabel) on \(nextTransitionDateFormatted(from: nextDate))")
            }
        }
    }

    private var fallbackDashaSection: some View {
        CosmicPulseView(
            currentDasha: DashaInfo(
                planet: "Unknown",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 365),
                currentYear: 1,
                totalYears: 7
            ),
            accuracyLevel: completeness.level,
            onTap: { activeSheet = .dashaDetail }
        )
    }

    private func nextTransitionDateFormatted(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Section 5: This Month Card

    private func thisMonthCard(_ prediction: MonthPrediction) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)
                Text(prediction.month)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Text(prediction.headline)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .accessibilityAddTraits(.isHeader)

            Divider()
                .background(Color.cosmicTextTertiary.opacity(0.15))

            // DO
            actionRow(
                icon: "checkmark.circle.fill",
                color: Color.cosmicSuccess,
                label: "DO",
                text: prediction.doAction
            )

            // AVOID
            actionRow(
                icon: "xmark.circle.fill",
                color: Color.cosmicError,
                label: "AVOID",
                text: prediction.avoidAction
            )

            // Transit triggers
            if !prediction.transitTriggers.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Text("Transit Triggers")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .cosmicUppercaseLabel()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            ForEach(prediction.transitTriggers, id: \.self) { trigger in
                                Text(trigger)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .padding(.horizontal, Cosmic.Spacing.sm)
                                    .padding(.vertical, Cosmic.Spacing.xxs)
                                    .background(
                                        RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                                            .fill(Color.cosmicAmethyst.opacity(0.12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                                            .stroke(Color.cosmicAmethyst.opacity(0.2), lineWidth: Cosmic.Border.hairline)
                                    )
                            }
                        }
                    }
                }
            }
        }
        .padding(Cosmic.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.08), lineWidth: Cosmic.Border.hairline)
        )
        .cosmicElevation(.low)
    }

    private func actionRow(icon: String, color: Color, label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.cosmicMicro)
                    .foregroundStyle(color)
                    .cosmicUppercaseLabel()
                Text(text)
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Cosmic.Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(text)")
    }

    // MARK: - Section 6: Peak Windows

    /// Number of peak windows shown free (approximates current quarter).
    private static let freePeakWindowCount = 2

    private func peakWindowsSection(_ windows: [MirrorPeakWindow], isPremium: Bool) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)
                Text("Peak Windows")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    if isPremium {
                        ForEach(windows) { window in
                            peakWindowCard(window)
                        }
                    } else {
                        // Free tier: first N windows free, rest gated
                        let freeWindows = windows.prefix(Self.freePeakWindowCount)
                        let hasLocked = windows.count > Self.freePeakWindowCount

                        ForEach(Array(freeWindows)) { window in
                            peakWindowCard(window)
                        }

                        if hasLocked {
                            PremiumLockCard(
                                featureName: "Peak Windows",
                                context: .peakWindows
                            )
                        }
                    }
                }
            }
        }
    }

    private func peakWindowCard(_ window: MirrorPeakWindow) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            // Probability badge
            Text(window.probability.uppercased())
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicGold)
                .padding(.horizontal, Cosmic.Spacing.xs)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                        .fill(Color.cosmicGold.opacity(0.12))
                )

            Text(window.theme)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(2)

            Text(window.dateRange)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(Cosmic.Spacing.md)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.08), lineWidth: Cosmic.Border.hairline)
        )
        .cosmicElevation(.subtle)
    }

    // MARK: - Section 7: Constraints (wrapped)

    private func constraintSection(_ constraints: [ChartConstraint]) -> some View {
        ConstraintCardView(constraints: constraints)
    }

    // MARK: - Section 8: Synthesis Narrative

    private func synthesisCard(_ narrative: String) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.cosmicGold)
                Text("Cosmic Synthesis")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityAddTraits(.isHeader)

            Text(narrative)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineSpacing(CosmicTypography.LineHeight.relaxed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Cosmic.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.cosmicGold.opacity(0.15), Color.cosmicGold.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Cosmic.Border.thin
                )
        )
        .cosmicElevation(.low)
    }

    // MARK: - Section 9: Journey Map Card

    private var journeyMapCard: some View {
        let progress = viewModel.mirrorData?.journeyProgress
        let levelTitle = progress?.levelTitle ?? gamification.level.title
        let streak = progress?.streak ?? gamification.streak
        let completed = progress?.completedMilestoneCount ?? gamification.milestones.count
        let total = progress?.totalMilestones ?? JourneyMilestone.allCases.count

        return Button {
            CosmicHaptics.light()
            activeSheet = .journeyMap
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Journey Map")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text(levelTitle)
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Streak")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text("\(streak)")
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicGold)
                            .monospacedDigit()
                    }
                }

                Text("\(completed) of \(total) milestones completed")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack(spacing: 6) {
                    ForEach(Array(JourneyMilestone.allCases.prefix(5)), id: \.self) { m in
                        Circle()
                            .fill(gamification.milestones.contains(m) ? Color.cosmicGold : Color.cosmicSurface)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(Color.cosmicGold.opacity(0.25), lineWidth: 1)
                            )
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
            .padding()
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                    .stroke(Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 10: Reports

    private var reportsSection: some View {
        Button {
            CosmicHaptics.medium()
            activeSheet = .reportShop
        } label: {
            HStack(spacing: Cosmic.Spacing.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Detailed Reports")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Deep cosmic insights generated from your chart")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(Cosmic.Spacing.md)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                    .stroke(Color.cosmicGold.opacity(0.08), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Detailed Reports. Browse cosmic reports.")
    }

    // MARK: - Account Footer

    private var accountFooter: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            if !hasProSubscription {
                Button {
                    activeSheet = .paywall
                } label: {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                        Text("Unlock Astronova Pro")
                            .font(.cosmicBodyEmphasis)
                    }
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(height: Cosmic.ButtonHeight.large)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.cosmicBrass, Color.cosmicGold, Color.cosmicCopper],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Unlock Astronova Pro")
            }

            // Settings link
            Button {
                activeSheet = .settings
            } label: {
                HStack(spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                    Text("Settings & Account")
                        .font(.cosmicCallout)
                    Spacer()
                }
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.vertical, Cosmic.Spacing.xs)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Journey Map Sheet (extracted from SelfTabView)

private struct JourneyMapSheet: View {
    @EnvironmentObject private var gamification: GamificationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Text("Seeker Level")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text(gamification.level.title)
                        .font(.cosmicTitle1)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("Milestones")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    ForEach(JourneyMilestone.allCases, id: \.self) { m in
                        HStack(spacing: Cosmic.Spacing.sm) {
                            Image(systemName: gamification.milestones.contains(m) ? "checkmark.seal.fill" : "circle")
                                .foregroundStyle(gamification.milestones.contains(m) ? Color.cosmicGold : Color.cosmicTextSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.title)
                                    .font(.cosmicCalloutEmphasis)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                Text(m.subtitle)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            }
            .padding()
        }
        .navigationTitle("Journey Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.cosmicGold)
            }
        }
        .background(Color.cosmicBackground)
    }
}

// MARK: - Cosmic Particle Field (reused from SelfTabView)

private struct CosmicParticleField: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            for i in 0..<20 {
                let seed = Double(i)
                let x = fmod(abs(Darwin.sin(seed * 12.9898 + 78.233) * 43758.5453), 1) * size.width
                let y = fmod(abs(Darwin.sin(seed * 93.9898 + phase * 0.1) * 43758.5453), 1) * size.height
                let particleSize = 1.5 + Darwin.sin(seed) * 0.5
                let opacity = 0.3 + Darwin.sin(phase + seed * 0.5) * 0.2

                context.opacity = opacity
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                    with: .color(Color.cosmicGold)
                )
            }

            for i in 0..<10 {
                let seed = Double(i) + 100
                let x = fmod(abs(Darwin.sin(seed * 12.9898 + 78.233) * 43758.5453), 1) * size.width
                let y = fmod(abs(Darwin.sin(seed * 93.9898 + 18.233) * 43758.5453), 1) * size.height
                let starSize = 1.0 + Darwin.sin(seed * 2) * 0.5
                let twinkle = 0.2 + Darwin.sin(phase * 2 + seed) * 0.15

                context.opacity = twinkle
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: starSize, height: starSize)),
                    with: .color(.white)
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sample Data for Previews

extension CosmicMirrorData {
    static var sample: CosmicMirrorData {
        CosmicMirrorData(
            archetype: .sample,
            matrixEntries: PlanetaryMatrixView.sampleEntries,
            constraints: ChartConstraint.samples,
            loshu: LoshuData.sample,
            currentMonthPrediction: MonthPrediction.sample,
            peakWindows: MirrorPeakWindow.samples,
            dashaPulse: DashaPulseData.sample,
            journeyProgress: JourneyProgressData.sample,
            synthesisNarrative: "Your chart reveals a rare convergence of 9th-house dharma and 10th-house karma, meaning what you do in the world IS your spiritual practice — not separate from it. The Leo ascendant with exalted Sun creates a natural radiance that draws opportunities, while the Saturn-Moon conjunction in the 4th ensures you never lose touch with the emotional depth that makes your output meaningful rather than merely impressive. Your current Jupiter dasha activates the 9th-10th axis, making these next 4 years your peak window for creating work that outlasts you."
        )
    }

    static var minimalSample: CosmicMirrorData {
        CosmicMirrorData(
            archetype: .alternateSample,
            matrixEntries: Array(PlanetaryMatrixView.sampleEntries.prefix(5)),
            constraints: Array(ChartConstraint.samples.prefix(2)),
            loshu: nil,
            currentMonthPrediction: nil,
            peakWindows: nil,
            dashaPulse: DashaPulseData.sample,
            journeyProgress: nil,
            synthesisNarrative: nil
        )
    }
}

extension MonthPrediction {
    static var sample: MonthPrediction {
        MonthPrediction(
            id: "2026-06",
            month: "June 2026",
            headline: "Jupiter Direct in 9th House",
            doAction: "Launch creative projects, publish your work, enroll in advanced training. Jupiter's direct motion in your dharma house makes this the month where effort multiplies.",
            avoidAction: "Don't scatter energy across too many initiatives. The Jupiter-Mars trine amplifies output but also the temptation to start everything at once. Pick one flagship project and ride it.",
            transitTriggers: ["Jupiter Direct · Jun 3", "Mars Trine Jupiter · Jun 12", "Mercury Sextile Sun · Jun 18"]
        )
    }
}

extension MirrorPeakWindow {
    static var samples: [MirrorPeakWindow] {
        [
            MirrorPeakWindow(
                id: "pw-1",
                dateRange: "Jun 3 – Jun 17",
                theme: "Career Breakthrough",
                headline: nil,
                probability: "Very High"
            ),
            MirrorPeakWindow(
                id: "pw-2",
                dateRange: "Jul 8 – Jul 22",
                theme: "Financial Windfall",
                headline: nil,
                probability: "High"
            ),
            MirrorPeakWindow(
                id: "pw-3",
                dateRange: "Aug 15 – Sep 2",
                theme: "Creative Recognition",
                headline: nil,
                probability: "Very High"
            ),
            MirrorPeakWindow(
                id: "pw-4",
                dateRange: "Oct 10 – Oct 28",
                theme: "Partnership Expansion",
                headline: nil,
                probability: "Moderate"
            ),
        ]
    }
}

extension DashaPulseData {
    static var sample: DashaPulseData {
        DashaPulseData(
            currentPlanet: "Jupiter",
            currentYear: 5,
            totalYears: 16,
            startDate: Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 11, to: Date()) ?? Date(),
            nextTransitionLabel: "Saturn Mahadasha",
            nextTransitionDate: Calendar.current.date(byAdding: .year, value: 11, to: Date()) ?? Date()
        )
    }
}

extension JourneyProgressData {
    static var sample: JourneyProgressData {
        JourneyProgressData(
            levelTitle: "Cosmic Apprentice",
            streak: 24,
            completedMilestoneCount: 6,
            totalMilestones: JourneyMilestone.allCases.count
        )
    }
}

// MARK: - Loshu Sample Data

extension LoshuData {
    static var sample: LoshuData {
        LoshuData(
            grid: [
                [4, 9, 2],
                [3, 5, 7],
                [8, 1, 6]
            ],
            counts: [
                "1": 2, "2": 1, "3": 0, "4": 1,
                "5": 0, "6": 1, "7": 0, "8": 2, "9": 3
            ],
            missing: [3, 5, 7],
            present: [1, 2, 4, 6, 8, 9],
            eigenvalues: [15.0, 6.708, 2.292],
            completedPlanes: [
                PlaneInfo(
                    name: "Top Row",
                    numbers: [4, 9, 2],
                    isComplete: true,
                    description: "Mental plane — governs thought, communication, and intellectual pursuits."
                ),
                PlaneInfo(
                    name: "Middle Row",
                    numbers: [3, 5, 7],
                    isComplete: false,
                    description: "Emotional plane — governs relationships, creativity, and inner balance."
                ),
                PlaneInfo(
                    name: "Bottom Row",
                    numbers: [8, 1, 6],
                    isComplete: true,
                    description: "Practical plane — governs material success, career, and physical health."
                ),
            ],
            driverNumber: 4,
            conductorNumber: 6
        )
    }
}

// MARK: - Previews

#Preview("Cosmic Mirror — Full Data") {
    CosmicMirrorView()
        .environmentObject(AuthState())
        .environmentObject(GamificationManager())
        .preferredColorScheme(.dark)
}

#Preview("Cosmic Mirror — Minimal Data") {
    let view = CosmicMirrorView()
        .environmentObject(AuthState())
        .environmentObject(GamificationManager())
        .preferredColorScheme(.dark)
    return view
}

#Preview("Cosmic Mirror — Loading") {
    CosmicMirrorView()
        .environmentObject(AuthState())
        .environmentObject(GamificationManager())
        .preferredColorScheme(.dark)
}

#Preview("Cosmic Mirror — Error") {
    let view = CosmicMirrorView()
        .environmentObject(AuthState())
        .environmentObject(GamificationManager())
        .preferredColorScheme(.dark)
    return view
}
