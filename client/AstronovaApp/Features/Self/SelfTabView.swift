import SwiftUI

// MARK: - Self Tab View
// "Living Cosmic Mirror" - Vedic-centric, dasha-focused, uniquely Astronova
// NOT a profile page. A portal to your current cosmic position.

struct SelfTabView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @StateObject private var dataService = SelfDataService()
    @AppStorage("hasAstronovaPro") private var hasProSubscription = false

    @State private var foundationExpanded = false
    @State private var activeSheet: SheetDestination?

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

                    // HERO: Cosmic Pulse (Dasha)
                    cosmicPulseSection

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
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .birthEdit:
                QuickBirthEditView()
                    .environmentObject(auth)
            case .settings:
                MoreOptionsSheet(bookmarks: .constant([]))
                    .environmentObject(auth)
            case .paywall:
                PaywallView()
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
    }

    // MARK: - Name Header

    private var nameHeader: some View {
        HStack {
            Text(profile.fullName.isEmpty ? "Cosmic Traveler" : profile.fullName)
                .font(.cosmicTitle1)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()
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

    // MARK: - Essence Section

    private var essenceSection: some View {
        EssenceBar(
            moonNakshatra: dataService.moonNakshatra,
            lagna: dataService.lagna,
            nakshatraLord: dataService.nakshatraLord
        )
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
            } else {
                // Empty state with CTA to browse reports
                ReportsEmptyState(onBrowse: { activeSheet = .reportShop })
            }
        }
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

                Button {
                    CosmicHaptics.medium()
                    onBrowse()
                } label: {
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
                .accessibilityIdentifier(AccessibilityID.reportsShopButton)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Cosmic.Spacing.lg)
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Self Tab") {
    SelfTabView()
        .environmentObject(AuthState())
}
