import SwiftUI
import UserNotifications

/// Main Discover tab view - daily check-in hub with life domain cards
struct DiscoverView: View {
    @EnvironmentObject private var auth: AuthState
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
    }
}
