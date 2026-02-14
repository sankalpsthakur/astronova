import SwiftUI
import UserNotifications

/// Main Discover tab view - daily check-in hub with life domain cards
struct DiscoverView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @StateObject private var viewModel = DiscoverViewModel()
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false

    @State private var showingReportSheet = false
    @State private var selectedReportType = ""
    @State private var showingReportsLibrary = false
    @State private var showingReportShop = false
    @State private var showingPaywall = false
    @State private var showingReportDetail = false
    @State private var selectedReport: DetailedReport?
    @State private var selectedDomainInsight: DomainInsight?
    @State private var showingShareSheet = false
    @State private var shareContent: String = ""
    @State private var showingReminderConfirmation = false
    @State private var reminderMessage = ""
    @State private var showingDailySignal = false

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.cosmicBackground
                .ignoresSafeArea()

            // Main content - "never blank" approach
            if let snapshot = viewModel.snapshot {
                contentView(snapshot)
            } else if viewModel.isLoading {
                // Show shimmer while loading
                DiscoverShimmerView()
            } else if let error = viewModel.error {
                errorState(error)
            } else {
                // Initial load - show shimmer
                DiscoverShimmerView()
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh(shouldLoadReports: auth.isAuthenticated)
        }
        .task {
            await viewModel.load(profile: auth.profileManager.profile, shouldLoadReports: auth.isAuthenticated)

            // Check if we should show report shop (triggered from PaywallView)
            if triggerShowReportShop {
                triggerShowReportShop = false
                showingReportShop = true
            }

            // Screenshot helper (UI test harness): auto-present daily signal.
            if TestEnvironment.shared.isUITest,
               ProcessInfo.processInfo.environment["UITEST_PRESENT_DAILY_SIGNAL"] == "1" {
                _ = gamification.drawTodaysSignal()
                showingDailySignal = true
            }
        }
        .onAppear {
            guard auth.isAuthenticated else { return }
            Task {
                await viewModel.loadUserReports()
            }
        }
        .onChange(of: triggerShowReportShop) { _, newValue in
            if newValue {
                triggerShowReportShop = false
                showingReportShop = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reportPurchased)) { _ in
            guard auth.isAuthenticated else { return }
            Task {
                await viewModel.loadUserReports()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: .home)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportGenerationSheet(
                reportType: selectedReportType,
                onGenerate: { type in
                    generateReport(type: type)
                },
                onDismiss: {
                    showingReportSheet = false
                }
            )
            .environmentObject(auth)
        }
        .sheet(isPresented: $showingReportsLibrary) {
            ReportsLibraryView(reports: viewModel.userReports)
        }
        .sheet(isPresented: $showingReportShop) {
            InlineReportsStoreSheet()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showingReportDetail) {
            if let report = selectedReport {
                ReportDetailView(report: report)
            }
        }
        .sheet(item: $selectedDomainInsight) { insight in
            DomainDetailView(
                insight: insight,
                hasSubscription: viewModel.hasSubscription,
                onGetReport: { reportType in
                    selectedDomainInsight = nil
                    selectedReportType = reportType
                    showingReportSheet = true
                },
                onUpgrade: {
                    selectedDomainInsight = nil
                    showingPaywall = true
                }
            )
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(_ snapshot: DiscoverSnapshot) -> some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.lg) {
                SeekerProgressHeader(
                    levelTitle: gamification.level.title,
                    streak: gamification.streak,
                    xpProgress: gamification.xpProgressToNextLevel,
                    weeklyTheme: gamification.weeklyTheme()
                ) {
                    let result = gamification.drawTodaysSignal()
                    if result.isNewCheckIn {
                        // Streak reward UX: light haptic already covered elsewhere; keep simple.
                    }
                    showingDailySignal = true
                }
                .padding(.horizontal, Cosmic.Spacing.m)
                .padding(.top, Cosmic.Spacing.m)

                ArcanaCollectionSection(
                    cards: gamification.allArcanaCards,
                    unlockedCardIds: gamification.unlockedCardIds,
                    currentCard: gamification.currentDailyCard
                )
                .padding(.horizontal, Cosmic.Spacing.m)

                WeeklyChallengeSection(
                    theme: gamification.weeklyTheme(),
                    isCompleted: gamification.isCurrentWeeklyChallengeComplete
                ) {
                    openWeeklyChallengeAction(gamification.weeklyTheme())
                }
                .padding(.horizontal, Cosmic.Spacing.m)

                // Life Domain Grid with Cosmic Weather header
                DomainGridView(
                    insights: viewModel.domainInsights,
                    horoscope: viewModel.dailyHoroscope,
                    onDomainTap: { insight in
                        selectedDomainInsight = insight
                    }
                )
                .padding(.horizontal, Cosmic.Spacing.m)
                .padding(.top, Cosmic.Spacing.m)

                // Keywords
                if let keywords = snapshot.keywords, !keywords.isEmpty {
                    keywordsView(keywords)
                }

                // Your Day - Narrative tiles
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("Your Day")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .padding(.horizontal, Cosmic.Spacing.m)
                        .accessibilityAddTraits(.isHeader)

                    NarrativeTilesView(tiles: snapshot.now.narrativeTiles) { tile in
                        #if DEBUG
                        debugPrint("[DiscoverView] Tile tapped: \(tile.id)")
                        #endif
                    }
                    .padding(.horizontal, Cosmic.Spacing.m)
                }

                // Next Up Timeline
                if let markers = snapshot.next.markers, !markers.isEmpty {
                    NextUpTimeline(
                        markers: markers,
                        nextShift: snapshot.next.shift,
                        onMarkerTap: { marker in
                            #if DEBUG
                            debugPrint("[DiscoverView] Marker tapped: \(marker.date)")
                            #endif
                        },
                        onTimeTravelTap: {
                            // Navigate to Time Travel tab (index 1)
                            NotificationCenter.default.post(name: .switchToTab, object: 1)
                        }
                    )
                    .padding(.horizontal, Cosmic.Spacing.m)
                }

                // Connections strip
                ConnectionsStrip(
                    connections: viewModel.connections,
                    onConnectionTap: { connection in
                        #if DEBUG
                        debugPrint("[DiscoverView] Connection tapped: \(connection.name)")
                        #endif
                    },
                    onSeeAllTap: {
                        // Navigate to Connect tab (index 3)
                        NotificationCenter.default.post(name: .switchToTab, object: 3)
                    }
                )
                .padding(.horizontal, Cosmic.Spacing.m)

                // Your Reports (if any)
                if !viewModel.userReports.isEmpty {
                    YourReportsSection(
                        reports: viewModel.userReports,
                        onReportTap: { report in
                            selectedReport = report
                            showingReportDetail = true
                        },
                        onViewAllTap: {
                            showingReportsLibrary = true
                        }
                    )
                    .padding(.horizontal, Cosmic.Spacing.m)
                }

                // Actions row
                actionsRow(snapshot)
                    .padding(.horizontal, Cosmic.Spacing.m)

                // Bottom padding for tab bar
                Color.clear.frame(height: 120)
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingDailySignal) {
            DailySignalSheet(
                card: gamification.currentDailyCard ?? gamification.drawTodaysSignal().card,
                theme: gamification.weeklyTheme(),
                archetype: gamification.archetype,
                onShare: {
                    gamification.markShared()
                }
            )
        }
    }

    private func openWeeklyChallengeAction(_ theme: WeeklyTheme) {
        switch theme {
        case .love:
            showingDailySignal = true
        case .career:
            NotificationCenter.default.post(name: .switchToTab, object: 3)
        case .calm:
            NotificationCenter.default.post(name: .switchToTab, object: 2)
        case .focus:
            NotificationCenter.default.post(name: .switchToTab, object: 1)
        }
    }

    // MARK: - Keywords View

    private func keywordsView(_ keywords: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Cosmic.Spacing.xs) {
                ForEach(keywords.prefix(6), id: \.self) { keyword in
                    Text(keyword.capitalized)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .padding(.horizontal, Cosmic.Spacing.sm)
                        .padding(.vertical, Cosmic.Spacing.xxs)
                        .background(Color.cosmicSurface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.cosmicGold.opacity(0.18), lineWidth: Cosmic.Border.hairline)
                        )
                }
            }
            .padding(.horizontal, Cosmic.Spacing.m)
        }
    }

    // MARK: - Actions Row

    private func actionsRow(_ snapshot: DiscoverSnapshot) -> some View {
        HStack(spacing: Cosmic.Spacing.m) {
            // Share button
            ShareLink(item: shareableText(from: snapshot)) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .accessibilityLabel("Share your daily insight")
            .accessibilityHint("Opens the share sheet")

            Spacer()

            // Reminder button
            Button {
                CosmicHaptics.light()
                scheduleReminder(for: snapshot)
            } label: {
                Label("Remind me", systemImage: "bell")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .accessibilityLabel("Set a reminder")
            .accessibilityHint("Schedules a daily reminder")
        }
        .padding(.vertical, Cosmic.Spacing.s)
        .alert("Reminder Set", isPresented: $showingReminderConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(reminderMessage)
        }
    }

    // MARK: - Share & Reminder Helpers

    private func shareableText(from snapshot: DiscoverSnapshot) -> String {
        var text = "✨ My Cosmic Insight for Today ✨\n\n"
        text += "Theme: \(snapshot.now.theme)\n\n"

        if let firstTile = snapshot.now.narrativeTiles.first {
            text += "\"\(firstTile.text)\"\n\n"
        }

        if let keywords = snapshot.keywords, !keywords.isEmpty {
            text += "Keywords: \(keywords.joined(separator: ", "))\n\n"
        }

        text += "— Astronova 🌟"
        return text
    }

    private func scheduleReminder(for snapshot: DiscoverSnapshot) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async {
                    reminderMessage = "Please enable notifications in Settings to use reminders."
                    showingReminderConfirmation = true
                }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "🌟 Your Daily Cosmic Check-in"
            content.body = "Today's theme: \(snapshot.now.theme). Tap to discover your insights!"
            content.sound = .default

            // Schedule for tomorrow at 8 AM
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "daily-cosmic-reminder", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        reminderMessage = "You'll be reminded tomorrow at 8:00 AM to check your cosmic insights!"
                        CosmicHaptics.success()
                    } else {
                        reminderMessage = "Could not set reminder. Please try again."
                    }
                    showingReminderConfirmation = true
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            Spacer()

            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 3)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.cosmicGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(viewModel.loadingRotation))
            }

            Text("Reading the cosmos...")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                viewModel.loadingRotation = 360
            }
        }
    }

    private struct ArcanaCollectionSection: View {
        let cards: [ArcanaCard]
        let unlockedCardIds: Set<String>
        let currentCard: ArcanaCard?

        var body: some View {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sigils & Arcana")
                            .font(.cosmicHeadline)
                        Text("Unlock cards by completing meaningful actions.")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    Spacer()
                }

                Text("\(unlockedCardIds.count) of \(cards.count)")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Cosmic.Spacing.xs) {
                    ForEach(cards, id: \.id) { card in
                        let unlocked = unlockedCardIds.contains(card.id)
                        let isCurrent = currentCard?.id == card.id
                        ArcanaCollectionCard(card: card, isUnlocked: unlocked, isCurrent: isCurrent)
                    }
                }
            }
            .padding()
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        }
    }

    private struct ArcanaCollectionCard: View {
        let card: ArcanaCard
        let isUnlocked: Bool
        let isCurrent: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                HStack {
                    Text(card.title)
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(isUnlocked ? Color.cosmicTextPrimary : Color.cosmicTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    if isCurrent {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.cosmicGold)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.cosmicTextSecondary.opacity(0.8))
                    }
                }

                Text(card.subtitle)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Text(isUnlocked ? "Unlocked" : "Locked")
                        .font(.cosmicMicro)
                        .foregroundStyle(isUnlocked ? Color.cosmicSuccess : Color.cosmicTextTertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .fill(isUnlocked ? Color.cosmicGold.opacity(0.16) : Color.cosmicSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                            .stroke(
                                isUnlocked
                                    ? Color.cosmicGold.opacity(0.45)
                                    : Color.cosmicTextTertiary.opacity(0.2),
                                lineWidth: Cosmic.Border.hairline
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .stroke(isCurrent ? Color.cosmicGold.opacity(0.8) : Color.clear, lineWidth: 1)
            )
        }
    }

    private struct WeeklyChallengeSection: View {
        let theme: WeeklyTheme
        let isCompleted: Bool
        let onAction: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Challenge")
                            .font(.cosmicHeadline)
                        Text(theme.title)
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    Spacer()

                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicSuccess)
                    }
                }

                Text(theme.weeklyChallenge)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack {
                    Text(theme.weeklyChallengeRewardText)
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(isCompleted ? Color.cosmicSuccess : Color.cosmicGold)

                    Spacer()

                    if isCompleted {
                        Text("Completed")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicSuccess)
                    } else {
                        Button {
                            onAction()
                        } label: {
                            Text("Take action")
                                .font(.cosmicCaptionEmphasis)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.cosmicGold.opacity(0.2), in: Capsule())
                                .foregroundStyle(Color.cosmicTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                    .fill(Color.cosmicSurface)
            )
        }
    }

    // MARK: - Error State

    private func errorState(_ error: String) -> some View {
        VStack(spacing: Cosmic.Spacing.m) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.cosmicTextSecondary)

            Text("Unable to load")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(error)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.load(profile: auth.profileManager.profile, shouldLoadReports: auth.isAuthenticated)
                }
            } label: {
                Text("Try Again")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.lg)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(Color.cosmicGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unable to load. \(error)")
        .accessibilityHint("Double tap Try Again to reload")
    }

    // MARK: - Helpers

    private func generateReport(type: String) {
        Task {
            do {
                let birthData = try BirthData(from: auth.profileManager.profile)
                let response = try await APIServices.shared.generateReport(
                    birthData: birthData,
                    type: type,
                    userId: ClientUserId.value()
                )
                await viewModel.loadUserReports()

                // Convert response to DetailedReport and show
                let report = DetailedReport(
                    reportId: response.reportId,
                    type: response.type,
                    title: response.title,
                    content: response.summary, // Use summary as initial content
                    summary: response.summary,
                    keyInsights: response.keyInsights,
                    downloadUrl: response.downloadUrl,
                    generatedAt: response.generatedAt,
                    userId: ClientUserId.value(),
                    status: response.status
                )

                // Dismiss sheet and show the generated report
                await MainActor.run {
                    showingReportSheet = false
                    selectedReport = report
                    showingReportDetail = true
                }
            } catch {
                #if DEBUG
                debugPrint("[DiscoverView] Failed to generate report: \(error)")
                #endif
                // Dismiss sheet even on error
                await MainActor.run {
                    showingReportSheet = false
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var snapshot: DiscoverSnapshot?
    @Published var userReports: [DetailedReport] = []
    @Published var connections: [ConnectionCard] = []
    @Published var domainInsights: [DomainInsight] = []
    @Published var dailyHoroscope: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasSubscription = false
    @Published var loadingRotation: Double = 0

    private let apiServices = APIServices.shared
    private let cache = DiscoverSnapshotCache.shared
    private let domainInsightsCache = DomainInsightsCache.shared

    func load(profile: UserProfile?, shouldLoadReports: Bool) async {
        // Check cache first
        if let cached = cache.get() {
            snapshot = cached
        }

        // Check domain insights cache
        if let cachedInsights = domainInsightsCache.get() {
            domainInsights = cachedInsights.insights
            dailyHoroscope = cachedInsights.horoscope
        }

        isLoading = true
        error = nil

        do {
            // Get sign from profile or default
            let sign = profile?.sunSign?.lowercased() ?? "aries"

            if TestEnvironment.shared.isUITest,
               ProcessInfo.processInfo.environment["UITEST_DISCOVER_SAMPLE"] == "1" {
                // Deterministic snapshot for simulator screenshots (no network dependency).
                snapshot = DiscoverSnapshot(
                    date: "2026-02-06",
                    sign: sign,
                    personalized: true,
                    now: DiscoverNow(
                        theme: "Clarity through small decisions",
                        narrativeTiles: [
                            NarrativeTile(id: "tile_1", text: "Energy peaks mid-day; schedule the hardest task first.", domain: "work", weight: 0.8, driver: nil),
                            NarrativeTile(id: "tile_2", text: "A simple message can soften tension today.", domain: "love", weight: 0.6, driver: nil),
                            NarrativeTile(id: "tile_3", text: "One short walk resets your mind.", domain: "mind", weight: 0.5, driver: nil),
                        ],
                        actions: [
                            DiscoverAction(id: "act_1", text: "Choose one priority and finish it.", type: "do"),
                            DiscoverAction(id: "act_2", text: "Avoid doomscrolling after 9pm.", type: "avoid"),
                        ]
                    ),
                    lens: CosmicLens(
                        energyState: EnergyState(id: "focused", label: "Focused", description: "Steady, forward energy.", icon: "bolt.fill"),
                        domainWeights: DomainWeights(self: 0.35, love: 0.22, work: 0.28, mind: 0.15),
                        activations: nil
                    ),
                    next: DiscoverNext(
                        shift: DiscoverNextShift(date: "2026-02-10", daysUntil: 4, level: "Antardasha", from: "Venus", to: "Mercury", summary: "Near-term focus sharpens; communication matters more."),
                        markers: nil
                    ),
                    lucky: nil,
                    keywords: ["focus", "calm", "momentum"],
                    cacheHints: CacheHints(ttlSeconds: 3600, nextRefresh: nil)
                )

                domainInsights = DomainInsight.samples
                dailyHoroscope = "Sample data (UI test mode)."
                hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
                if shouldLoadReports {
                    await loadUserReports()
                } else {
                    userReports = []
                }
                loadConnections()
                isLoading = false
                return
            }

            // Fetch snapshot and domain insights in parallel
            async let snapshotTask = apiServices.getDiscoverSnapshot(sign: sign)
            async let domainTask = apiServices.getDomainInsights()

            let (newSnapshot, (insights, horoscope)) = try await (snapshotTask, domainTask)

            snapshot = newSnapshot
            cache.set(newSnapshot)

            // Update domain insights
            domainInsights = insights.isEmpty ? DomainInsight.samples : insights
            dailyHoroscope = horoscope
            domainInsightsCache.set(insights: domainInsights, horoscope: dailyHoroscope)

            // Check subscription
            hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")

            // Load user reports
            if shouldLoadReports {
                await loadUserReports()
            } else {
                userReports = []
            }

            // Load connections (placeholder - would come from saved connections)
            loadConnections()

        } catch {
            self.error = error.localizedDescription

            // Use sample data as fallback for domain insights
            if domainInsights.isEmpty {
                domainInsights = DomainInsight.samples
            }

            // If we have cached data, keep showing it
            if snapshot == nil {
                self.error = "Unable to connect. Please check your connection."
            }
        }

        isLoading = false
    }

    func refresh(shouldLoadReports: Bool) async {
        cache.clear()
        domainInsightsCache.clear()
        await load(profile: nil, shouldLoadReports: shouldLoadReports)
    }

    func loadUserReports() async {
        do {
            let reports = try await apiServices.getUserReports(userId: ClientUserId.value())
            userReports = reports
        } catch {
            // Keep existing reports on error
            #if DEBUG
            debugPrint("[DiscoverView] Failed to load reports: \(error)")
            #endif
        }
    }

    private func loadConnections() {
        // Placeholder - would load from saved connections
        // For now, return empty to show the "Add connection" CTA
        connections = []
    }
}

// MARK: - Domain Insights Cache

class DomainInsightsCache {
    static let shared = DomainInsightsCache()

    private var cachedInsights: [DomainInsight]?
    private var cachedHoroscope: String?
    private var cacheTime: Date?
    private let ttl: TimeInterval = 3600 // 1 hour

    func get() -> (insights: [DomainInsight], horoscope: String?)? {
        guard let cached = cachedInsights,
              let time = cacheTime,
              Date().timeIntervalSince(time) < ttl else {
            return nil
        }
        return (cached, cachedHoroscope)
    }

    func set(insights: [DomainInsight], horoscope: String?) {
        cachedInsights = insights
        cachedHoroscope = horoscope
        cacheTime = Date()
    }

    func clear() {
        cachedInsights = nil
        cachedHoroscope = nil
        cacheTime = nil
    }
}

// MARK: - Cache

class DiscoverSnapshotCache {
    static let shared = DiscoverSnapshotCache()

    private var cachedSnapshot: DiscoverSnapshot?
    private var expiresAt: Date?
    private let defaultTTL: TimeInterval = 3600 // 1 hour
    private let isoFormatter = ISO8601DateFormatter()
    private let fallbackFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    func get() -> DiscoverSnapshot? {
        guard let cached = cachedSnapshot else {
            return nil
        }
        if let expiresAt, Date() >= expiresAt {
            clear()
            return nil
        }
        return cached
    }

    func set(_ snapshot: DiscoverSnapshot) {
        cachedSnapshot = snapshot
        expiresAt = computeExpiry(for: snapshot)
    }

    func clear() {
        cachedSnapshot = nil
        expiresAt = nil
    }

    private func computeExpiry(for snapshot: DiscoverSnapshot) -> Date {
        if let nextRefresh = snapshot.cacheHints?.nextRefresh {
            if let date = isoFormatter.date(from: nextRefresh) ?? fallbackFormatter.date(from: nextRefresh) {
                return date
            }
        }
        if let ttlSeconds = snapshot.cacheHints?.ttlSeconds {
            return Date().addingTimeInterval(TimeInterval(ttlSeconds))
        }
        return Date().addingTimeInterval(defaultTTL)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DiscoverView()
            .environmentObject(AuthState())
            .environmentObject(GamificationManager())
    }
}

// MARK: - Gamification UI

private struct SeekerProgressHeader: View {
    let levelTitle: String
    let streak: Int
    let xpProgress: Double
    let weeklyTheme: WeeklyTheme
    let onDrawSignal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seeker Level")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text(levelTitle)
                        .font(.cosmicTitle2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Streak")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicGold)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly theme: \(weeklyTheme.title)")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cosmicSurface)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cosmicGold.opacity(0.8))
                            .frame(width: max(10, geo.size.width * xpProgress))
                    }
                }
                .frame(height: 10)
                .accessibilityLabel("Level progress")
                .accessibilityValue("\(Int(xpProgress * 100)) percent")
            }

            Button {
                CosmicHaptics.light()
                onDrawSignal()
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "sparkles")
                    Text("Draw today's signal")
                        .font(.cosmicCalloutEmphasis)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                        .stroke(Color.cosmicGold.opacity(0.18), lineWidth: Cosmic.Border.hairline)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cosmicBackground, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                .stroke(Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.hairline)
        )
    }
}

private struct DailySignalSheet: View {
    let card: ArcanaCard
    let theme: WeeklyTheme
    let archetype: String?
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Cosmic.Spacing.lg) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Text("Today's Signal")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    Text(card.title)
                        .font(.cosmicTitle1)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(card.subtitle)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("Weekly theme: \(theme.title)")
                        .font(.cosmicCaptionEmphasis)
                    if let archetype, !archetype.isEmpty {
                        Text("Archetype: \(archetype)")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    Text(card.prompt)
                        .font(.cosmicBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                ShareLink(item: card.shareText(archetype: archetype, theme: theme)) {
                    Text("Share your daily insight card")
                        .font(.cosmicCalloutEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cosmicGold, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                        .foregroundStyle(Color.cosmicVoid)
                }
                .simultaneousGesture(TapGesture().onEnded { onShare() })

                Spacer()
            }
            .padding()
            .navigationTitle("Signal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
