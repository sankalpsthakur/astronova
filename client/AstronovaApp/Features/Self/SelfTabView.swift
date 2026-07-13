import SwiftUI
import AVFoundation
import UIKit

// MARK: - Self Tab View
// "Living Cosmic Mirror" - Vedic-centric, dasha-focused, uniquely Astronova
// NOT a profile page. A portal to your current cosmic position.

struct SelfTabView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @StateObject private var dataService = SelfDataService()
    @AppStorage("hasAstronovaPro") private var hasProSubscription = false
    /// Audit A0d: one-time hint about approximate Lagna / house calculations
    /// when the user opted out of providing a precise birth time.
    @AppStorage("self.approximateBirthTimeHintDismissed") private var approximateHintDismissed = false

    @State private var foundationExpanded = false
    @State private var activeSheet: SheetDestination?

    // A2 — Chart-load chime (one-shot per session).
    // See `launch-artifacts/feedback-design-wave-2026-05-18.md` §1.1 A2.
    @State private var chartLoadAudioPlayer: AVAudioPlayer?
    @State private var didChimeChartLoad = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile {
        auth.profileManager.profile
    }

    private var completeness: ProfileCompleteness {
        ProfileCompleteness(profile: profile)
    }

    private enum SheetDestination: Identifiable {
        case birthEdit
        case settings
        case paywall
        case dashaDetail
        case journeyMap
        case reportDetail(DetailedReport)
        case reportShop
        case reportsLibrary
        case journalCompose
        case cosmicMirror
        case numberLattice
        case predictionTimeline
        case astrocartography
        case freeWillBlend

        var id: String {
            switch self {
            case .birthEdit:
                return "birthEdit"
            case .settings:
                return "settings"
            case .paywall:
                return "paywall"
            case .dashaDetail:
                return "dashaDetail"
            case .journeyMap:
                return "journeyMap"
            case .reportDetail(let report):
                return "reportDetail-\(report.reportId)"
            case .reportShop:
                return "reportShop"
            case .reportsLibrary:
                return "reportsLibrary"
            case .journalCompose:
                return "journalCompose"
            case .cosmicMirror:
                return "cosmicMirror"
            case .numberLattice:
                return "numberLattice"
            case .predictionTimeline:
                return "predictionTimeline"
            case .astrocartography:
                return "astrocartography"
            case .freeWillBlend:
                return "freeWillBlend"
            }
        }
    }

    // Non-blocking: calculations work with minimal data
    private var canFetchData: Bool {
        completeness.canCalculateDasha
    }

    var body: some View {
        ZStack {
            // Cosmic void background with particle drift
            cosmicBackground

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: Cosmic.Spacing.xl) {
                    // Name header (minimal)
                    nameHeader
                        .padding(.top, Cosmic.Spacing.lg)

                    // Entertainment disclaimer (audit A0c): small caption above
                    // the Cosmic Pulse hero, prominent without being intrusive.
                    Text(AstronovaCopy.shortAstrologyDisclaimer)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("self.disclaimer")

                    // HERO: Cosmic Pulse (Dasha)
                    cosmicPulseSection

                    // High-value analysis modules from the design bundle.
                    analysisModulesSection

                    // Journey Map (gamified progression)
                    JourneyMapCard(
                        levelTitle: gamification.level.title,
                        streak: gamification.streak,
                        milestones: gamification.milestones
                    ) {
                        activeSheet = .journeyMap
                    }

                    // Essence Bar (Nakshatra + Lagna) - requires full data for lagna
                    if completeness.canCalculateLagna && (dataService.moonNakshatra != nil || dataService.lagna != nil) {
                        // Audit A0d: one-time hint when the user explicitly
                        // toggled "unknown" birth time. Shown directly above
                        // the section that displays the approximate Lagna so
                        // the warning has context.
                        if profile.isBirthTimeApproximate && !approximateHintDismissed {
                            approximateBirthTimeHint
                        }
                        essenceSection
                    }

                    // Unlock prompt for next improvement
                    if let nextUnlock = completeness.nextUnlock {
                        UnlockPromptView(item: nextUnlock, onTap: { activeSheet = .birthEdit })
                    }

                    // Today's Energy (Transit strengths)
                    todaysEnergySection

                    // Your Reports section
                    reportsSection

                    // Foundation (Birth data, collapsible)
                    foundationSection

                    // Account Footer
                    accountSection

                    // Bottom spacing for tab bar
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
            .refreshable {
                await dataService.refresh(for: profile)
                if auth.isAuthenticated {
                    await dataService.fetchReports()
                } else {
                    dataService.stopReportPolling()
                }
            }

            // Loading overlay
            if dataService.isLoading {
                loadingOverlay
            }
        }
        .accessibilityIdentifier(AccessibilityID.selfTabView)
        .task {
            // Non-blocking: fetch data even with minimal profile (just birth date)
            if canFetchData {
                await dataService.fetchData(for: profile)
            }
            if auth.isAuthenticated {
                await dataService.fetchReports()
            } else {
                dataService.stopReportPolling()
            }
            // Wave 13 — chart_viewed event (portfolio standard).
            Analytics.shared.track(.chartViewed, properties: [
                "chart_type": "natal_summary",
                "is_paid": UserDefaults.standard.bool(forKey: "hasAstronovaPro") ? "true" : "false"
            ])
            // Peak-trigger review prompt: this is the user's primary daily
            // surface — the first time it renders after a chart is computed,
            // ask for a review (subject to 6-month throttle).
            await MainActor.run {
                AstronovaReviewPrompts.shared.requestIfPeak(.firstChartCompleted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reportPurchased)) { _ in
            guard auth.isAuthenticated else { return }
            Task {
                await dataService.fetchReports()
            }
        }
        .onDisappear {
            dataService.stopReportPolling()
        }
        .onChange(of: completeness.level) { oldLevel, newLevel in
            // Refetch when profile completeness improves (more accurate data available)
            if newLevel.rawValue > oldLevel.rawValue && canFetchData {
                Task {
                    await dataService.fetchData(for: profile)
                }
            }
        }
        .onChange(of: profile.birthDate) { _, _ in
            // Refetch when birth date changes
            if canFetchData {
                Task {
                    await dataService.fetchData(for: profile)
                }
            }
        }
        .onChange(of: dataService.currentDasha?.planet) { oldValue, newValue in
            // A2 — Chart-load chime. Fires once per session when the natal
            // dasha data first arrives (nil → non-nil). Subsequent refreshes
            // do not retrigger so the cue stays meaningful.
            // See `launch-artifacts/feedback-design-wave-2026-05-18.md` §1.1 A2.
            guard !didChimeChartLoad,
                  oldValue == nil,
                  newValue != nil else { return }
            didChimeChartLoad = true
            fireChartLoadCue()
        }
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
                    JourneyMapView()
                        .environmentObject(gamification)
                }
            case .reportDetail(let report):
                ReportDetailView(report: report)
            case .reportShop:
                InlineReportsStoreSheet()
                    .environmentObject(auth)
            case .reportsLibrary:
                ReportsLibraryView(reports: dataService.userReports)
            case .journalCompose:
                JournalComposeView()
            case .cosmicMirror:
                NavigationStack {
                    CosmicMirrorView()
                        .environmentObject(auth)
                        .environmentObject(gamification)
                }
            case .numberLattice:
                NavigationStack {
                    NumberLatticeSheetView()
                }
            case .predictionTimeline:
                PredictionTimelineView()
                    .environmentObject(auth)
            case .astrocartography:
                NavigationStack {
                    AstrocartographyMapView()
                        .navigationTitle("Best Places")
                        .navigationBarTitleDisplayMode(.inline)
                }
            case .freeWillBlend:
                NavigationStack {
                    BayesianSliderView()
                        .navigationTitle("Free Will")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Cosmic Background

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

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.cosmicVoid.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Cosmic.Spacing.md) {
                LoadingView(style: .cosmic, message: "Aligning with the cosmos...")
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Name Header

    private var nameHeader: some View {
        HStack {
            Text(profile.fullName.isEmpty ? "Cosmic Traveler" : profile.fullName)
                .font(.cosmicTitle1)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            Button {
                CosmicHaptics.medium()
                activeSheet = .reportShop
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
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
            .accessibilityLabel("Reports Shop")
            .accessibilityIdentifier(AccessibilityID.reportsShopButton)
        }
    }

    // MARK: - Cosmic Pulse Section

    private var cosmicPulseSection: some View {
        Group {
            if canFetchData {
                // Show dasha even with basic data (birth date only)
                // Accuracy indicator shows user they can improve
                    CosmicPulseView(
                        currentDasha: dataService.currentDasha ?? fallbackDasha,
                        accuracyLevel: completeness.level,
                        onTap: { activeSheet = .dashaDetail }
                    )
            } else {
                CosmicPulseEmptyView(onSetup: { activeSheet = .birthEdit })
            }
        }
    }

    // MARK: - Analysis Modules Section

    private var analysisModulesSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                Text(analysisEyebrow)
                    .font(.cosmicMicro)
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .accessibilityIdentifier("analysis.commandCenter.eyebrow")
                Text("Analysis command center")
                    .font(.cosmicTitle3)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text("System overview, number lattice, place, transition, and agency before you write.")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Cosmic.Spacing.xs) {
                analysisMetric("LIVE", "0.82")
                analysisMetric("PROC", "9/9")
                analysisMetric("NEXT", "04 Oct")
                analysisMetric("CITY", "Dubai 0.91")
            }
            .accessibilityIdentifier("analysis.liveState.metrics")

            Button {
                CosmicHaptics.medium()
                activeSheet = .journalCompose
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log today's signal")
                            .font(.cosmicCaptionEmphasis)
                        Text("Turn the live read into a saved decision trace.")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicVoid.opacity(0.72))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.cosmicVoid)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicGold))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Log today's signal")
            .accessibilityIdentifier("analysis.logTodaySignal.button")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Cosmic.Spacing.s) {
                ForEach(analysisModules) { module in
                    analysisModuleButton(module)
                }
            }
        }
        .accessibilityIdentifier("analysis.modules.section")
    }

    private var analysisEyebrow: String {
        let name = profile.fullName
            .split(separator: " ")
            .first
            .map { String($0).uppercased() }
        return "\(name ?? "GUEST") · CHART/PROD"
    }

    private var analysisModules: [AnalysisModule] {
        [
            AnalysisModule(title: "System overview", eyebrow: "SYSTEM OVERVIEW", subtitle: "12 server rooms. 9 daemons. 1 you.", metric: "0.82 · 9/9 running", status: "LIVE", icon: "server.rack", identifier: "analysis.cosmicMirror.button", destination: .cosmicMirror),
            AnalysisModule(title: "Number lattice", eyebrow: "NUMEROLOGY · LOSHU 3x3", subtitle: "Date + phone + name vectors", metric: "Missing 8 · driver 4", status: "CLIENT", icon: "square.grid.3x3.fill", identifier: "analysis.numberLattice.button", destination: .numberLattice),
            AnalysisModule(title: "Where else", eyebrow: "ASTROCARTOGRAPHY · ACG/v2", subtitle: "Apple Maps globe and ranked cities", metric: "Dubai 0.91 · Singapore 0.82", status: "MAPS", icon: "globe.americas.fill", identifier: "analysis.astrocartography.button", destination: .astrocartography),
            AnalysisModule(title: "The shift", eyebrow: "MAHA-DASHA · CURRENT > NEXT", subtitle: "Jupiter now, Saturn next", metric: "Migration checklist · 134 days", status: "SERVER", icon: "arrow.left.arrow.right", identifier: "analysis.predictionTimeline.button", destination: .predictionTimeline),
            AnalysisModule(title: "Free will", eyebrow: "MODEL · BAYESIAN BLEND", subtitle: "Priors meet your likelihoods", metric: "w = 0.55 agency", status: "LIVE", icon: "slider.horizontal.3", identifier: "analysis.freeWill.button", destination: .freeWillBlend)
        ]
    }

    private func analysisMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.cosmicMicro)
                .tracking(0.8)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.cosmicMicro)
                .fontWeight(.semibold)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.hairline)
        )
    }

    private func analysisModuleButton(_ module: AnalysisModule) -> some View {
        Button {
            CosmicHaptics.medium()
            activeSheet = module.destination
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                HStack(alignment: .top) {
                    Image(systemName: module.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 34, height: 34)
                        .background(Color.cosmicGold.opacity(0.12), in: Circle())
                    Spacer(minLength: 0)
                    Text(module.status)
                        .font(.cosmicMicro)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.cosmicGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cosmicGold.opacity(0.12)))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(module.eyebrow)
                        .font(.cosmicMicro)
                        .tracking(0.7)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(module.title)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(module.subtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(2)
                    Text(module.metric)
                        .font(.cosmicMicro)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.cosmicTextPrimary.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .padding(Cosmic.Spacing.m)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(module.identifier)
    }

    private struct AnalysisModule: Identifiable {
        let title: String
        let eyebrow: String
        let subtitle: String
        let metric: String
        let status: String
        let icon: String
        let identifier: String
        let destination: SheetDestination

        var id: String { identifier }
    }

    // MARK: - Essence Section

    private var essenceSection: some View {
        EssenceBar(
            moonNakshatra: dataService.moonNakshatra,
            lagna: dataService.lagna,
            nakshatraLord: dataService.nakshatraLord,
            // Audit A0d: server computed Lagna against a 12:00 noon stand-in
            // when the user toggled "unknown" birth time; flag the chip so
            // users see the reading isn't precise.
            lagnaIsApproximate: profile.isBirthTimeApproximate
        )
    }

    // MARK: - Approximate Birth Time Hint

    private var approximateBirthTimeHint: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            Image(systemName: "clock.badge.questionmark")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicWarning)
            Text("Without a precise birth time, ascendant and house calculations are approximate.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button {
                approximateHintDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(4)
            }
            .accessibilityLabel("Dismiss birth time hint")
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicWarning.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicWarning.opacity(0.25), lineWidth: 0.5)
                )
        )
        .accessibilityIdentifier("self.approximateBirthTimeHint")
    }

    // MARK: - Today's Energy Section

    private var todaysEnergySection: some View {
        Group {
            if canFetchData {
                if dataService.planetaryStrengths.isEmpty {
                    if dataService.isLoading {
                        TodaysEnergyEmptyView(
                            title: "Calculating your energy",
                            message: "We're generating your planetary strengths now."
                        )
                    } else if dataService.error != nil {
                        TodaysEnergyEmptyView(
                            title: "Energy reading unavailable",
                            message: "We couldn't calculate your energy. Check your birth time and place, then try again."
                        )
                    } else {
                        TodaysEnergyEmptyView(
                            title: "Energy reading unavailable",
                            message: "We don't have enough data yet. Add your birth time and place to calculate."
                        )
                    }
                } else {
                    // Show planetary strengths with available data
                    TodaysEnergyView(
                        planetaryStrengths: dataService.planetaryStrengths,
                        dominantPlanet: dataService.dominantPlanet
                    )
                }
            } else {
                TodaysEnergyEmptyView()
            }
        }
    }

    // MARK: - Reports Section

    private var reportsSection: some View {
        Group {
            if !dataService.userReports.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    YourReportsSection(
                        reports: dataService.userReports,
                        onReportTap: { report in
                            if report.status?.lowercased() == "completed" {
                                activeSheet = .reportDetail(report)
                            }
                        },
                        onViewAllTap: {
                            activeSheet = .reportsLibrary
                        }
                    )

                    reportsShopButton
                }
            } else {
                // Empty state with CTA to browse reports
                ReportsEmptyState(onBrowse: { activeSheet = .reportShop })
            }
        }
    }

    private var reportsShopButton: some View {
        Button {
            CosmicHaptics.medium()
            activeSheet = .reportShop
        } label: {
            HStack(spacing: Cosmic.Spacing.s) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                Text("Browse More Reports")
                    .font(.cosmicCalloutEmphasis)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.cosmicGold)
            .padding(Cosmic.Spacing.m)
            .background(Color.cosmicGold.opacity(0.12), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.16), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reportsShopSecondaryButton")
    }

    // MARK: - Foundation Section

    private var foundationSection: some View {
        FoundationSection(
            isExpanded: $foundationExpanded,
            onEditBirth: { activeSheet = .birthEdit },
            onViewChart: { activeSheet = .dashaDetail }
        )
    }

    // MARK: - Account Section

    private var accountSection: some View {
        AccountFooter(
            isPro: hasProSubscription,
            onUpgrade: { activeSheet = .paywall },
            onSettings: { activeSheet = .settings }
        )
    }

    // MARK: - Computed Properties

    // Fallback dasha while loading or if API fails
    private var fallbackDasha: DashaInfo {
        DashaInfo(
            planet: "Unknown",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 365),
            currentYear: 1,
            totalYears: 7
        )
    }

    // MARK: - A2 Chart-Load Cue

    /// Fires the haptic + bell + VoiceOver announcement triplet once the
    /// natal chart data finishes loading. Per
    /// `launch-artifacts/feedback-design-wave-2026-05-18.md` §1.1 A2.
    /// Uses its own AVAudioPlayer instance — does NOT tap the bell player
    /// owned by `TempleBellAnimationView`.
    private func fireChartLoadCue() {
        HapticFeedbackService.shared.loadingComplete()

        // VoiceOver parallel signal (§0.4 accessibility floor).
        UIAccessibility.post(notification: .announcement,
                             argument: "Your chart is ready")

        // Lazy-init a per-view bell player. Failures are non-fatal.
        if chartLoadAudioPlayer == nil,
           let url = Bundle.main.url(forResource: "bell", withExtension: "wav") {
            chartLoadAudioPlayer = try? AVAudioPlayer(contentsOf: url)
            chartLoadAudioPlayer?.prepareToPlay()
        }
        chartLoadAudioPlayer?.currentTime = 0
        chartLoadAudioPlayer?.play()
    }
}

private struct JourneyMapCard: View {
    let levelTitle: String
    let streak: Int
    let milestones: Set<JourneyMilestone>
    let onOpen: () -> Void

    var body: some View {
        Button {
            CosmicHaptics.light()
            onOpen()
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

                let completed = milestones.count
                Text("\(completed) milestone\(completed == 1 ? "" : "s") completed")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack(spacing: 6) {
                    ForEach(JourneyMilestone.allCases.prefix(5), id: \.self) { m in
                        Circle()
                            .fill(milestones.contains(m) ? Color.cosmicGold : Color.cosmicSurface)
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
}

private struct JourneyMapView: View {
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
                }
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("Milestones")
                        .font(.cosmicHeadline)
                    ForEach(JourneyMilestone.allCases, id: \.self) { m in
                        HStack(spacing: Cosmic.Spacing.sm) {
                            Image(systemName: gamification.milestones.contains(m) ? "checkmark.seal.fill" : "circle")
                                .foregroundStyle(gamification.milestones.contains(m) ? Color.cosmicGold : Color.cosmicTextSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.title)
                                    .font(.cosmicCalloutEmphasis)
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
            }
        }
    }
}

// MARK: - Cosmic Particle Field

private struct CosmicParticleField: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            // Gold particles (sparse)
            for i in 0..<20 {
                let seed = Double(i)
                let x = fmod(abs(sin(seed * 12.9898 + 78.233) * 43758.5453), 1) * size.width
                let y = fmod(abs(sin(seed * 93.9898 + phase * 0.1) * 43758.5453), 1) * size.height
                let particleSize = 1.5 + sin(seed) * 0.5
                let opacity = 0.3 + sin(phase + seed * 0.5) * 0.2

                context.opacity = opacity
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                    with: .color(Color.cosmicGold)
                )
            }

            // White stars (very sparse)
            for i in 0..<10 {
                let seed = Double(i) + 100
                let x = fmod(abs(sin(seed * 12.9898 + 78.233) * 43758.5453), 1) * size.width
                let y = fmod(abs(sin(seed * 93.9898 + 18.233) * 43758.5453), 1) * size.height
                let starSize = 1.0 + sin(seed * 2) * 0.5
                let twinkle = 0.2 + sin(phase * 2 + seed) * 0.15

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

// MARK: - Reports Empty State

private struct ReportsEmptyState: View {
    let onBrowse: () -> Void

    var body: some View {
        Button {
            CosmicHaptics.medium()
            onBrowse()
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
                HStack {
                    Text("Your Reports")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Spacer()
                }

                VStack(spacing: Cosmic.Spacing.m) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.cosmicGold.opacity(0.5))

                    Text("Deep cosmic insights await")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Explore Reports")
                    }
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.lg)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Cosmic.Spacing.lg)
            }
            .padding(Cosmic.Spacing.m)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reportsShopSecondaryButton")
    }
}

// MARK: - Preview

#Preview("Self Tab") {
    SelfTabView()
        .environmentObject(AuthState())
}
