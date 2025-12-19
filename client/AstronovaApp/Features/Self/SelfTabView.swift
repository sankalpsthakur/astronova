import SwiftUI

// MARK: - Self Tab View
// "Living Cosmic Mirror" - Vedic-centric, dasha-focused, uniquely Astronova
// NOT a profile page. A portal to your current cosmic position.

struct SelfTabView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var dataService = SelfDataService()

    @State private var showingBirthEdit = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingDashaDetail = false
    @State private var foundationExpanded = false
    @State private var showingReportDetail = false
    @State private var selectedReport: DetailedReport?
    @State private var showingReportShop = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile {
        auth.profileManager.profile
    }

    private var completeness: ProfileCompleteness {
        ProfileCompleteness(profile: profile)
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

                    // Essence Bar (Nakshatra + Lagna) - requires full data for lagna
                    if completeness.canCalculateLagna && (dataService.moonNakshatra != nil || dataService.lagna != nil) {
                        essenceSection
                    }

                    // Unlock prompt for next improvement
                    if let nextUnlock = completeness.nextUnlock {
                        UnlockPromptView(item: nextUnlock, onTap: { showingBirthEdit = true })
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
                await dataService.fetchReports()
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
            await dataService.fetchReports()
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
        .sheet(isPresented: $showingBirthEdit) {
            QuickBirthEditView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showingSettings) {
            MoreOptionsSheet(bookmarks: .constant([]))
                .environmentObject(auth)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingDashaDetail) {
            NavigationStack {
                EnhancedTimeTravelView()
                    .environmentObject(auth)
            }
        }
        .sheet(isPresented: $showingReportDetail) {
            if let report = selectedReport {
                ReportDetailView(report: report)
            }
        }
        .sheet(isPresented: $showingReportShop) {
            InlineReportsStoreSheet()
                .environmentObject(auth)
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
                    onTap: { showingDashaDetail = true }
                )
            } else {
                CosmicPulseEmptyView(onSetup: { showingBirthEdit = true })
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
                // Show planetary strengths with available data
                TodaysEnergyView(
                    planetaryStrengths: dataService.planetaryStrengths.isEmpty
                        ? PlanetaryStrength.sample
                        : dataService.planetaryStrengths,
                    dominantPlanet: dataService.dominantPlanet
                )
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
                            selectedReport = report
                            showingReportDetail = true
                        }
                    },
                    onViewAllTap: {
                        showingReportShop = true
                    }
                )
            } else {
                // Empty state with CTA to browse reports
                ReportsEmptyState(onBrowse: { showingReportShop = true })
            }
        }
    }

    // MARK: - Foundation Section

    private var foundationSection: some View {
        FoundationSection(
            isExpanded: $foundationExpanded,
            onEditBirth: { showingBirthEdit = true },
            onViewChart: { showingDashaDetail = true }
        )
    }

    // MARK: - Account Section

    private var accountSection: some View {
        AccountFooter(
            isPro: isPro,
            onUpgrade: { showingPaywall = true },
            onSettings: { showingSettings = true }
        )
    }

    // MARK: - Computed Properties

    private var isPro: Bool {
        #if DEBUG
        return BasicStoreManager.shared.hasProSubscription
        #else
        return StoreKitManager.shared.hasProSubscription
        #endif
    }

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
