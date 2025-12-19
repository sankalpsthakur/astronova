import SwiftUI
import UserNotifications

struct HomeView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var vm: HomeViewModel
    @State private var mood: Double = 0.5
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var notificationAuthorized = false
    @State private var selectedTopic: DailyTopic?

    @State private var showingReportSheet = false
    @State private var showingReportsLibrary = false
    @State private var showingReportShop = false
    @State private var selectedReportType: String = ""
    @State private var userReports: [DetailedReport] = []
    @State private var hasSubscription = false
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false

    private let apiServices = APIServices.shared

    init(name: String? = nil, profileManager: UserProfileManager? = nil) {
        let pm = profileManager ?? AuthState().profileManager
        _vm = StateObject(wrappedValue: HomeViewModel(profileManager: pm))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
                Text(headerTitle)
                    .font(SwiftUI.Font.cosmicTitle)
                    .foregroundStyle(Color.cosmicTextPrimary)

                if let g = vm.guidance {
                    HStack(spacing: Cosmic.Spacing.s) {
                        Button {
                            CosmicHaptics.light()
                            selectedTopic = .focus
                        } label: {
                            QuickTile(title: "Focus", gradient: .cosmicCoolGradient, detail: g.focus)
                        }
                        .buttonStyle(.plain)

                        Button {
                            CosmicHaptics.light()
                            selectedTopic = .relationships
                        } label: {
                            QuickTile(
                                title: "Relationships",
                                gradient: LinearGradient(
                                    colors: [.planetVenus, .cosmicPrimary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                detail: g.relationships
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            CosmicHaptics.light()
                            selectedTopic = .energy
                        } label: {
                            QuickTile(title: "Energy", gradient: .cosmicSunsetGradient, detail: g.energy)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Tap a tile to open the deep dive.")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .padding(.top, 2)

                    if let keywords = g.keywords, !keywords.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Cosmic.Spacing.xs) {
                                ForEach(keywords.prefix(6), id: \.self) { keyword in
                                    Text(keyword.capitalized)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.cosmicSurface)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.cosmicGold.opacity(0.18), lineWidth: Cosmic.Border.hairline)
                                        )
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        Text("Deepen your day")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        PremiumInsightsSection(
                            hasSubscription: hasSubscription,
                            onInsightTap: { reportType in
                                selectedReportType = reportType
                                showingReportSheet = true
                            },
                            onViewReports: {
                                showingReportsLibrary = true
                            },
                            savedReports: userReports
                        )
                    }

                    Button {
                        showingReportShop = true
                    } label: {
                        HStack(spacing: Cosmic.Spacing.s) {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Explore all reports (from $12.99)")
                                .font(.cosmicCallout)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.cosmicCaption)
                        }
                        .padding(Cosmic.Spacing.m)
                        .background(Color.cosmicSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                                .stroke(Color.cosmicGold.opacity(0.25), lineWidth: Cosmic.Border.hairline)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Button {
                            if let img = ShareImageService.snapshot(of: shareCard(for: g)) {
                                shareImage = img; showShareSheet = true
                            }
                        } label: {
                            Label("Share Today", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                        if !notificationAuthorized {
                            Button {
                                Task { await requestDailyReminder() }
                            } label: {
                                Label("Enable reminder", systemImage: "bell")
                            }
                        }
                    }
                } else if vm.isLoading {
                    ProgressView().padding(.vertical, Cosmic.Spacing.xxl)
                } else if let error = vm.error {
                    Text(error)
                        .font(SwiftUI.Font.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    Text("Check-in")
                        .font(SwiftUI.Font.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    HStack(spacing: Cosmic.Spacing.s) {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(Color.cosmicAccent)
                        Slider(value: $mood)
                            .tint(Color.cosmicPrimary)
                    }
                }
            }
            .padding(Cosmic.Spacing.m)
            .padding(.bottom, 120) // keep content above floating tab bar
        }
        .background(Color.cosmicBackground)
        .sheet(isPresented: $vm.showPaywall) { PaywallView(context: .home) }
        .sheet(item: $selectedTopic) { topic in
            if let g = vm.guidance {
                DailyDeepDiveSheet(
                    topic: topic,
                    guidance: g,
                    hasSubscription: hasSubscription,
                    onUnlock: { vm.showPaywall = true },
                    onGenerateReport: { reportType in
                        selectedReportType = reportType
                        showingReportSheet = true
                    }
                )
                .environmentObject(auth)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportGenerationSheet(
                reportType: selectedReportType,
                onGenerate: generateReport,
                onDismiss: {
                    showingReportSheet = false
                }
            )
            .environmentObject(auth)
        }
        .sheet(isPresented: $showingReportsLibrary) {
            ReportsLibraryView(reports: userReports)
        }
        .sheet(isPresented: $showingReportShop, onDismiss: { Task { await loadUserReports() } }) {
            InlineReportsStoreSheet()
                .environmentObject(auth)
        }
        .task {
            checkSubscriptionStatus()
            await vm.load()
            await refreshNotificationAuth()
            await loadUserReports()

            if triggerShowReportShop {
                triggerShowReportShop = false
                showingReportShop = true
            }
        }
        .onAppear { Analytics.shared.track(.homeViewed, properties: nil) }
    }

    private var headerTitle: String {
        let name = auth.profileManager.profile.fullName
        return name.isEmpty ? "Today" : "Today for \(name)"
    }

    private func checkSubscriptionStatus() {
        hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }

    private func loadUserReports() async {
        do {
            let reports = try await apiServices.getUserReports(userId: currentUserId())
            var loaded = reports
            if loaded.isEmpty && TestEnvironment.shared.isUITest {
                let now = ISO8601DateFormatter().string(from: Date())
                loaded = [
                    DetailedReport(
                        reportId: UUID().uuidString,
                        type: "birth_chart",
                        title: "Test Report",
                        content: "UITEST placeholder content",
                        summary: "UITEST placeholder summary",
                        keyInsights: ["UITEST insight"],
                        downloadUrl: "/api/v1/reports/dummy/pdf",
                        generatedAt: now,
                        userId: currentUserId(),
                        status: "completed"
                    )
                ]
            }
            userReports = loaded
        } catch {
            if TestEnvironment.shared.isUITest {
                let now = ISO8601DateFormatter().string(from: Date())
                userReports = [
                    DetailedReport(
                        reportId: UUID().uuidString,
                        type: "birth_chart",
                        title: "Test Report",
                        content: "UITEST placeholder content",
                        summary: "UITEST placeholder summary",
                        keyInsights: ["UITEST insight"],
                        downloadUrl: "/api/v1/reports/dummy/pdf",
                        generatedAt: now,
                        userId: currentUserId(),
                        status: "completed"
                    )
                ]
            } else {
                userReports = []
            }
        }
    }

    private func generateReport(reportType: String) {
        Task {
            do {
                let birthData = try BirthData(from: auth.profileManager.profile)
                _ = try await apiServices.generateReport(birthData: birthData, type: reportType, userId: currentUserId())
                await loadUserReports()
            } catch {
                #if DEBUG
                debugPrint("[HomeView] Failed to generate report: \(error)")
                #endif
            }
        }
    }

    private func currentUserId() -> String {
        let key = "client_user_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    private func shareCard(for g: DailyGuidance) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            Text("Today for \(auth.profileManager.profile.fullName.isEmpty ? g.sign : auth.profileManager.profile.fullName)")
                .font(SwiftUI.Font.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
            HStack(spacing: Cosmic.Spacing.s) {
                miniTile("Focus", g.focus, .cosmicPrimary)
                miniTile("Relationships", g.relationships, .planetVenus)
                miniTile("Energy", g.energy, .planetSun)
            }
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .frame(width: 800, height: 400)
    }

    private func miniTile(_ title: String, _ detail: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text(title)
                .font(SwiftUI.Font.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(detail)
                .font(SwiftUI.Font.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(Cosmic.Spacing.s)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.button))
    }

    private func refreshNotificationAuth() async {
        let status = await NotificationService.shared.authorizationStatus()
        await MainActor.run { notificationAuthorized = (status == .authorized || status == .provisional) }
    }

    private func requestDailyReminder() async {
        let granted = await NotificationService.shared.requestAuthorization()
        if granted {
            let hour = Int(RemoteConfigService.shared.number(forKey: "daily_notification_default_hour", default: 9))
            await NotificationService.shared.scheduleDailyReminder(at: hour)
        }
        await refreshNotificationAuth()
        Analytics.shared.track(.notificationOptInPrompted, properties: ["granted": String(granted)])
        if granted { Analytics.shared.track(.notificationOptedIn, properties: nil) }
    }
}

private enum DailyTopic: String, CaseIterable, Identifiable {
    case focus
    case relationships
    case energy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .relationships: return "Relationships"
        case .energy: return "Energy"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "target"
        case .relationships: return "heart.fill"
        case .energy: return "bolt.fill"
        }
    }

    var suggestedReportType: String {
        switch self {
        case .focus: return "career_forecast"
        case .relationships: return "love_forecast"
        case .energy: return "year_ahead"
        }
    }
}

private struct DailyDeepDiveSheet: View {
    let topic: DailyTopic
    let guidance: DailyGuidance
    let hasSubscription: Bool
    let onUnlock: () -> Void
    let onGenerateReport: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var detail: String {
        switch topic {
        case .focus: return guidance.focus
        case .relationships: return guidance.relationships
        case .energy: return guidance.energy
        }
    }

    private var deeperText: String {
        if let t = guidance.horoscopeText, !t.isEmpty { return t }
        if let s = guidance.sourceSummary, !s.isEmpty { return s }
        return "Based on your horoscope + current sky conditions, this theme is more active today than usual."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    HStack(spacing: Cosmic.Spacing.s) {
                        Image(systemName: topic.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.cosmicGold)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.title)
                                .font(.cosmicTitle2)
                                .foregroundStyle(Color.cosmicTextPrimary)
                            Text("Today • \(guidance.sign)")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        Text("Guidance")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)
                        Text(detail)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .lineSpacing(4)
                    }
                    .padding(Cosmic.Spacing.m)
                    .background(Color.cosmicSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                            .stroke(Color.cosmicGold.opacity(0.18), lineWidth: Cosmic.Border.hairline)
                    )

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        HStack {
                            Text("Deeper why")
                                .font(.cosmicHeadline)
                                .foregroundStyle(Color.cosmicTextPrimary)
                            Spacer()
                            if !hasSubscription {
                                Label("Pro", systemImage: "lock.fill")
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                        }

                        Group {
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(deeperText)

                                if let luckyNumbers = guidance.luckyNumbers, !luckyNumbers.isEmpty {
                                    Text("Lucky numbers: \(luckyNumbers.map(String.init).joined(separator: ", "))")
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                }

                                if let keywords = guidance.keywords, !keywords.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Cosmic.Spacing.xs) {
                                            ForEach(keywords.prefix(8), id: \.self) { keyword in
                                                Text(keyword.capitalized)
                                                    .font(.cosmicCaption)
                                                    .foregroundStyle(Color.cosmicTextPrimary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.cosmicSurface)
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.cosmicGold.opacity(0.18), lineWidth: Cosmic.Border.hairline)
                                                    )
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineSpacing(4)
                        .blur(radius: hasSubscription ? 0 : 6)
                        .overlay(alignment: .center) {
                            if !hasSubscription {
                                Button {
                                    CosmicHaptics.medium()
                                    onUnlock()
                                } label: {
                                    Label("Unlock Astronova Pro", systemImage: "sparkles")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding(Cosmic.Spacing.m)
                    .background(Color.cosmicSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        Text("Go deeper")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Button {
                            CosmicHaptics.light()
                            dismiss()
                            onGenerateReport(topic.suggestedReportType)
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext")
                                Text("Generate a \(reportName(for: topic.suggestedReportType))")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.cosmicCaption)
                            }
                            .font(.cosmicCallout)
                            .padding(Cosmic.Spacing.m)
                            .background(Color.cosmicSurface)
                            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                                    .stroke(Color.cosmicGold.opacity(0.25), lineWidth: Cosmic.Border.hairline)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Cosmic.Spacing.m)
            }
            .background(Color.cosmicBackground)
            .navigationTitle("Deep Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
    }

    private func reportName(for type: String) -> String {
        switch type {
        case "love_forecast": return "Love Forecast"
        case "career_forecast": return "Career Forecast"
        case "year_ahead": return "Year Ahead"
        case "birth_chart": return "Birth Chart Reading"
        default: return "Report"
        }
    }
}

private struct QuickTile: View {
    let title: String
    let gradient: LinearGradient
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text(title.uppercased())
                .font(.cosmicCaption)
                .tracking(CosmicTypography.Tracking.uppercase)
                .foregroundStyle(Color.cosmicGold)
            Text(detail)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(3)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(Cosmic.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(gradient, lineWidth: Cosmic.Border.medium)
                )
        )
        .cosmicElevation(.low)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthState())
    }
}
#endif
