import SwiftUI

// MARK: - Journal Tab Landing

struct JournalView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @StateObject private var journal = JournalStore.shared
    @StateObject private var pauseLog = PauseLogStore.shared
    @StateObject private var quota = ProQuotaManager.shared
    @StateObject private var decisionStore = DecisionStore.shared
    @AppStorage("hasAstronovaPro") private var hasPro: Bool = false
    @State private var tab: Tab = .timeline
    @State private var filter: TimelineFilter = .all
    @State private var showCompose = false
    @State private var showDecisionCompose = false
    @State private var showingPaywall = false
    @State private var showInsightsLimitBanner = false
    @State private var activeAnalysisSheet: AnalysisSheet?
    @State private var pendingDecisionResult: Decision?

    enum Tab: String, CaseIterable, Identifiable {
        case timeline, insights
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum TimelineFilter: Hashable {
        case all, pauseOnly, thisWeek
        case pattern(String)
    }

    enum AnalysisSheet: String, Identifiable {
        case freeWillBlend

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicCosmos.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        agencyLoopSection
                        tabBar
                        if showInsightsLimitBanner && tab == .timeline {
                            insightsLimitBanner
                        }
                        if tab == .timeline {
                            filterBar
                            timeline
                        } else {
                            if !hasPro {
                                Text("Pro · used \(quota.insightsViewsUsedThisMonth) / \(ProQuotaManager.insightsMonthlyLimit) this month")
                                    .font(.cosmicLabel).tracking(0.8)
                                    .foregroundStyle(Color.cosmicTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20).padding(.bottom, 6)
                            }
                            InsightsView()
                        }
                    }
                    .padding(.bottom, 132)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticFeedbackService.shared.lightImpact()
                        showCompose = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.cosmicBodyEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    .accessibilityIdentifier(AccessibilityID.journalAddButton)
                }
            }
            .sheet(isPresented: $showCompose) { JournalComposeView() }
            .fullScreenCover(isPresented: $showDecisionCompose) {
                DecisionComposeView { pendingDecisionResult = $0 }
            }
            .sheet(isPresented: $showingPaywall) { PaywallVariantRouter(context: .journalInsights) }
            .sheet(item: $activeAnalysisSheet) { destination in
                analysisSheet(destination)
            }
            .navigationDestination(for: JournalEntry.self) { JournalEntryDetailView(entry: $0) }
            .navigationDestination(for: Decision.self) { DecisionResultView(decision: $0) }
            .navigationDestination(isPresented: Binding(
                get: { pendingDecisionResult != nil },
                set: { if !$0 { pendingDecisionResult = nil } }
            )) {
                if let decision = pendingDecisionResult {
                    DecisionResultView(decision: decision)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier(AccessibilityID.journalView)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Journal")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("What happened. What you noticed. What you'll do next.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.top, 58).padding(.bottom, 14)
    }

    private func analysisSheet(_ destination: AnalysisSheet) -> some View {
        ZStack(alignment: .topTrailing) {
            analysisSheetContent(destination)

            Button {
                HapticFeedbackService.shared.lightImpact()
                activeAnalysisSheet = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("analysis.sheet.close")
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }

    @ViewBuilder
    private func analysisSheetContent(_ destination: AnalysisSheet) -> some View {
        switch destination {
        case .freeWillBlend:
            NavigationStack {
                BayesianSliderView()
                    .navigationTitle("Free Will")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var agencyLoopSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(agencyEyebrow)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .tracking(1.4)

                Text("Free Will loop")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Tune agency, run the decision, then write what changed.")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            freeWillHero
            decisionLoopSection

            Button {
                HapticFeedbackService.shared.lightImpact()
                showCompose = true
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
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicAccent))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Log today's signal")
            .accessibilityIdentifier("journal.logTodaySignal.button")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var agencyEyebrow: String {
        let name = auth.profileManager.profile.fullName
            .split(separator: " ")
            .first
            .map { String($0).uppercased() }
        return "\(name ?? "GUEST") · AGENCY"
    }

    private var freeWillHero: some View {
        Button {
            HapticFeedbackService.shared.lightImpact()
            activeAnalysisSheet = .freeWillBlend
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicAccent)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.cosmicAccent.opacity(0.14)))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Free Will")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)
                        Text("Blend prediction with agency before you log the next move.")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }

                HStack(spacing: 8) {
                    agencyMetric("PRIORS", "stored")
                    agencyMetric("LIKELIHOOD", "live")
                    agencyMetric("AGENCY", "tunable")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.cosmicAccent.opacity(0.16), lineWidth: 0.5)
            )
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("journal.freeWillHero")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("journal.freeWillHero")
    }

    private var decisionLoopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Decision loop")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityIdentifier("journal.decisionLoop")
                    Text("Simulate the call, then save the learning below.")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer(minLength: 0)

                Button {
                    HapticFeedbackService.shared.mediumImpact()
                    if quota.canRunDecision {
                        showDecisionCompose = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.cosmicAccent))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Decision")
                .accessibilityIdentifier(AccessibilityID.decisionNewButton)
            }

            let recent = Array(decisionStore.recent().prefix(2))
            if recent.isEmpty {
                Text("No decisions yet. Start with one live question and let the result become a journal trace.")
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurfaceSecondary))
            } else {
                VStack(spacing: 8) {
                    ForEach(recent) { decision in
                        NavigationLink(value: decision) {
                            journalDecisionRow(decision)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !hasPro {
                Text("\(quota.decisionsRemaining) free decisions left this month")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.14), lineWidth: 0.5)
        )
    }

    private func agencyMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
                .tracking(0.8)
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
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.cosmicSurfaceSecondary))
    }

    private func journalDecisionRow(_ decision: Decision) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicGold)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.cosmicGold.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                Text(decision.promptText)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)
                Text(decision.decisionClass.label.uppercased())
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .tracking(0.7)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurfaceSecondary))
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { v in
                Button {
                    HapticFeedbackService.shared.selection()
                    if v == .insights {
                        if quota.canViewInsights {
                            showInsightsLimitBanner = false
                            tab = v
                            quota.recordInsightsView()
                        } else {
                            showInsightsLimitBanner = true
                            showingPaywall = true
                        }
                    } else {
                        tab = v
                    }
                } label: {
                    Text(v.label)
                        .font(.cosmicFootnoteEmphasis)
                        .foregroundStyle(tab == v ? Color.cosmicTextPrimary : Color.cosmicTextSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(tab == v ? Color.cosmicStardust : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(v == .timeline ? AccessibilityID.journalTimelineTabButton : AccessibilityID.journalInsightsTabButton)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.bottom, 12)
    }

    private var insightsLimitBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicAccent)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Journal Insights used")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("You used \(quota.insightsViewsUsedThisMonth) / \(ProQuotaManager.insightsMonthlyLimit) sessions this month. Pro keeps pattern, body, and mood trends open.")
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button {
                HapticFeedbackService.shared.lightImpact()
                showingPaywall = true
            } label: {
                HStack {
                    Text("Unlock Journal Insights")
                        .font(.cosmicFootnoteEmphasis)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.cosmicCaptionEmphasis)
                }
                .foregroundStyle(Color.cosmicVoid)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicAccent))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(AccessibilityID.journalInsightsUpgradeButton)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.journalInsightsUpgradeButton)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .accessibilityIdentifier(AccessibilityID.journalInsightsGateBanner)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", active: filter == .all) { filter = .all }
                Menu {
                    ForEach(TopoContentLoader.shared.patterns) { p in
                        Button(p.name) { filter = .pattern(p.id) }
                    }
                } label: { chipLabel(patternFilterLabel, active: isPatternFilter) }
                filterChip("Pause-only", active: filter == .pauseOnly) { filter = .pauseOnly }
                filterChip("This week", active: filter == .thisWeek) { filter = .thisWeek }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
    }

    private var patternFilterLabel: String {
        if case .pattern(let pid) = filter,
           let p = TopoContentLoader.shared.pattern(id: pid) { return p.name }
        return "By pattern"
    }
    private var isPatternFilter: Bool {
        if case .pattern = filter { return true }; return false
    }

    private func filterChip(_ text: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedbackService.shared.selection(); action()
        } label: { chipLabel(text, active: active) }
        .buttonStyle(.plain)
    }

    private func chipLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.cosmicCaptionEmphasis)
            .foregroundStyle(active ? Color.cosmicVoid : Color.cosmicTextSecondary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(active ? Color.cosmicAmethyst : Color.cosmicStardust))
    }

    private var timeline: some View {
        let items = mergedItems()
        return Group {
            if items.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        switch item {
                        case .journal(let e):
                            NavigationLink(value: e) { JournalRowView(entry: e) }
                                .buttonStyle(.plain)
                        case .pause(let e):
                            PauseRowView(entry: e)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 40)
            }
        }
    }

    private func mergedItems() -> [TimelineItem] {
        let journals = journal.entries.map { TimelineItem.journal($0) }
        let pauses = pauseLog.entries.map { TimelineItem.pause($0) }
        let merged: [TimelineItem]
        switch filter {
        case .all: merged = journals + pauses
        case .pattern(let pid):
            merged = journals.filter {
                if case .journal(let e) = $0 { return e.patternId == pid }
                return false
            }
        case .pauseOnly: merged = pauses
        case .thisWeek:
            let cutoff = Date().addingTimeInterval(-7 * 86400)
            merged = (journals + pauses).filter { $0.date >= cutoff }
        }
        return merged.sorted { $0.date > $1.date }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "pencil.line")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.cosmicTextTertiary)
            Text("Your timeline starts when you save the first signal. Use the command center or tap +.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }
}

struct NumberLatticeSheetView: View {
    var body: some View {
        LoshuGridView(data: .sample)
            .navigationTitle("Number lattice")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("numberLatticeView")
    }
}

// MARK: - Timeline item union

private enum TimelineItem: Identifiable {
    case journal(JournalEntry)
    case pause(PauseLogEntry)
    var id: String {
        switch self {
        case .journal(let e): return "j_\(e.id.uuidString)"
        case .pause(let e):   return "p_\(e.id.uuidString)"
        }
    }
    var date: Date {
        switch self {
        case .journal(let e): return e.createdAt
        case .pause(let e):   return e.timestamp
        }
    }
}

// MARK: - Timeline rows

private struct JournalRowView: View {
    let entry: JournalEntry
    private var patternName: String? {
        guard let pid = entry.patternId else { return nil }
        return TopoContentLoader.shared.pattern(id: pid)?.name
    }
    private var moodDelta: String? {
        guard let b = entry.moodBefore, let a = entry.moodAfter else { return nil }
        let d = a - b
        return "\(d >= 0 ? "+" : "")\(d)"
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pencil.line")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicAmethyst)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.cosmicAmethyst.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
                Text(entry.whatHappened.isEmpty ? "(no summary)" : entry.whatHappened)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1).truncationMode(.tail)
                if patternName != nil || moodDelta != nil {
                    HStack(spacing: 8) {
                        if let n = patternName {
                            Text(n).font(.cosmicLabel)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                        if let d = moodDelta {
                            Text(d).font(.cosmicLabel).monospaced()
                                .foregroundStyle(Color.cosmicTextTertiary)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
    }
}

private struct PauseRowView: View {
    let entry: PauseLogEntry
    private var tint: Color { planetTint(for: entry.planet) }
    private var moodLine: String {
        let after = entry.moodAfter.map(String.init) ?? "—"
        var s = "\(entry.moodBefore) → \(after)"
        if let step = entry.abandonedAtStep { s += " · abandoned at step \(step)" }
        return s
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(tint).frame(width: 10, height: 10)
                .padding(9)
                .background(Circle().fill(tint.opacity(0.15)))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
                Text("Pause · \(entry.emotion)")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(moodLine)
                    .font(.cosmicLabel).monospaced()
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
    }
}

// MARK: - Compose

struct JournalComposeView: View {
    @Environment(\.dismiss) private var dismiss
    private let editingEntry: JournalEntry?
    private let restoredDraft: JournalComposeDraft?

    @State private var whatHappened: String
    @State private var bodyRegions: Set<String>
    @State private var bodyNotes: String
    @State private var storyCreated: String
    @State private var selectedPatternId: String?
    @State private var whatIDid: String
    @State private var higherRoute: String
    @State private var learning: String
    @State private var moodBefore: Double
    @State private var moodAfter: Double
    @State private var draftStatusVisible: Bool

    static let regionOptions: [String] = [
        "head", "face", "throat", "chest", "heart", "stomach",
        "gut", "back", "shoulders", "jaw", "fists", "legs", "elsewhere"
    ]

    init(entry: JournalEntry? = nil) {
        self.editingEntry = entry
        let draft = entry == nil ? JournalComposeDraft.load() : nil
        self.restoredDraft = draft
        _whatHappened = State(initialValue: entry?.whatHappened ?? draft?.whatHappened ?? "")
        _bodyRegions = State(initialValue: Set(entry?.bodyRegions ?? draft?.bodyRegions ?? []))
        _bodyNotes = State(initialValue: entry?.bodyNotes ?? draft?.bodyNotes ?? "")
        _storyCreated = State(initialValue: entry?.storyCreated ?? draft?.storyCreated ?? "")
        _selectedPatternId = State(initialValue: entry?.patternId ?? draft?.selectedPatternId)
        _whatIDid = State(initialValue: entry?.whatIDid ?? draft?.whatIDid ?? "")
        _higherRoute = State(initialValue: entry?.higherRoute ?? draft?.higherRoute ?? "")
        _learning = State(initialValue: entry?.learning ?? draft?.learning ?? "")
        _moodBefore = State(initialValue: Double(entry?.moodBefore ?? draft?.moodBefore ?? 50))
        _moodAfter = State(initialValue: Double(entry?.moodAfter ?? draft?.moodAfter ?? 50))
        _draftStatusVisible = State(initialValue: draft != nil)
    }

    private var isValid: Bool {
        !whatHappened.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicCosmos.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        if draftStatusVisible {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.cosmicFootnote)
                                    .foregroundStyle(Color.cosmicAccent)
                                Text(restoredDraft == nil ? "Draft saved on this device" : "Draft restored from your last session")
                                    .font(.cosmicFootnote)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cosmicSurface))
                            .accessibilityIdentifier(AccessibilityID.journalDraftRestoredBanner)
                        }
                        composeSection("01 · What happened?") {
                            TextEditor(text: $whatHappened)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 78)
                                .font(.cosmicCallout)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .composeFieldBackground()
                                .accessibilityIdentifier(AccessibilityID.journalWhatHappenedEditor)
                        }
                        composeSection("02 · Body response") {
                            FlowChips(options: Self.regionOptions, selection: $bodyRegions)
                            TextField("notes", text: $bodyNotes)
                                .textFieldStyle(.plain)
                                .composeFieldBackground()
                                .padding(.top, 6)
                        }
                        composeSection("03 · Story you created") {
                            composeField($storyCreated, placeholder: "They don't respect my ideas. / I'm not enough. / etc.")
                        }
                        composeSection("04 · Pattern activated") { patternPicker }
                        composeSection("05 · What I did") {
                            composeField($whatIDid, placeholder: "Your move.")
                        }
                        composeSection("06 · Higher route") {
                            composeField($higherRoute, placeholder: "What you could have done.")
                        }
                        composeSection("07 · Learning") {
                            composeField($learning, placeholder: "What this taught me.")
                        }
                        moodFooter
                        actions
                    }
                    .padding(20).padding(.bottom, 40)
                }
            }
            .accessibilityIdentifier(AccessibilityID.journalComposeView)
            .navigationTitle(editingEntry == nil ? "New entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticFeedbackService.shared.lightImpact(); dismiss()
                    }
                    .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
            .onChange(of: whatHappened) { persistDraft() }
            .onChange(of: bodyRegions) { persistDraft() }
            .onChange(of: bodyNotes) { persistDraft() }
            .onChange(of: storyCreated) { persistDraft() }
            .onChange(of: selectedPatternId) { persistDraft() }
            .onChange(of: whatIDid) { persistDraft() }
            .onChange(of: higherRoute) { persistDraft() }
            .onChange(of: learning) { persistDraft() }
            .onChange(of: moodBefore) { persistDraft() }
            .onChange(of: moodAfter) { persistDraft() }
        }
    }

    private func composeField(_ binding: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .composeFieldBackground()
    }

    private func composeSection<C: View>(_ caption: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption.uppercased())
                .font(.cosmicMicro).tracking(1.2)
                .foregroundStyle(Color.cosmicTextTertiary)
            content()
        }
    }

    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                Button("no pattern fits") { selectedPatternId = nil }
                Divider()
                ForEach(TopoContentLoader.shared.patterns) { p in
                    Button(p.name) { selectedPatternId = p.id }
                }
            } label: {
                HStack {
                    Text(selectedPatternName)
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurface))
            }
            if let pid = selectedPatternId, let p = TopoContentLoader.shared.pattern(id: pid) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.name)
                        .font(.cosmicFootnoteEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(p.summary)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cosmicAmethyst.opacity(0.08)))
            }
        }
    }

    private var selectedPatternName: String {
        if let pid = selectedPatternId, let p = TopoContentLoader.shared.pattern(id: pid) {
            return p.name
        }
        return "Select a pattern"
    }

    private var moodFooter: some View {
        HStack(spacing: 14) {
            moodSlider("Mood before", value: $moodBefore)
            moodSlider("Mood after", value: $moodAfter)
        }
    }

    private func moodSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.cosmicMicro).tracking(1.0)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.cosmicCaptionEmphasis).monospaced()
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            Slider(value: value, in: 0...100, step: 1).tint(Color.cosmicAccent)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurface))
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                HapticFeedbackService.shared.lightImpact(); dismiss()
            } label: {
                Text("Cancel")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
            }
            .buttonStyle(.plain)
            Button {
                Task { @MainActor in save() }
            } label: {
                Text("Save")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isValid ? Color.cosmicAccent : Color.cosmicTextTertiary.opacity(0.4)))
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
            .accessibilityIdentifier(AccessibilityID.journalSaveButton)
        }
        .padding(.top, 6)
    }

    private func persistDraft() {
        guard editingEntry == nil else { return }
        JournalComposeDraft(
            whatHappened: whatHappened,
            bodyRegions: Array(bodyRegions).sorted(),
            bodyNotes: bodyNotes,
            storyCreated: storyCreated,
            selectedPatternId: selectedPatternId,
            whatIDid: whatIDid,
            higherRoute: higherRoute,
            learning: learning,
            moodBefore: Int(moodBefore),
            moodAfter: Int(moodAfter)
        ).save()
        draftStatusVisible = true
    }

    @MainActor
    private func save() {
        guard isValid else { return }
        let base = editingEntry
        let entry = JournalEntry(
            id: base?.id ?? UUID(),
            createdAt: base?.createdAt ?? Date(),
            whatHappened: whatHappened,
            bodyRegions: Array(bodyRegions),
            bodyNotes: bodyNotes,
            storyCreated: storyCreated,
            patternId: selectedPatternId,
            whatIDid: whatIDid,
            higherRoute: higherRoute,
            learning: learning,
            moodBefore: Int(moodBefore),
            moodAfter: Int(moodAfter),
            linkedPauseEntryId: base?.linkedPauseEntryId
        )
        if editingEntry == nil { JournalStore.shared.add(entry) }
        else { JournalStore.shared.update(entry) }
        if editingEntry == nil {
            JournalComposeDraft.clear()
        }
        HapticFeedbackService.shared.success()
        dismiss()
    }
}

private struct JournalComposeDraft: Codable {
    private static let storageKey = "topo.journal.compose.draft.v1"

    var whatHappened: String
    var bodyRegions: [String]
    var bodyNotes: String
    var storyCreated: String
    var selectedPatternId: String?
    var whatIDid: String
    var higherRoute: String
    var learning: String
    var moodBefore: Int
    var moodAfter: Int

    static func load() -> JournalComposeDraft? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(JournalComposeDraft.self, from: data)
    }

    func save() {
        guard hasContent else {
            Self.clear()
            return
        }
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private var hasContent: Bool {
        !whatHappened.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !bodyRegions.isEmpty ||
        !bodyNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !storyCreated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedPatternId != nil ||
        !whatIDid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !higherRoute.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !learning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        moodBefore != 50 ||
        moodAfter != 50
    }
}

private extension View {
    func composeFieldBackground() -> some View {
        self.padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cosmicSurface))
    }
}

// MARK: - Flow chips + layout

private struct FlowChips: View {
    let options: [String]
    @Binding var selection: Set<String>
    var body: some View {
        TopoFlowLayout(spacing: 8, runSpacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    HapticFeedbackService.shared.selection()
                    if selection.contains(option) { selection.remove(option) }
                    else { selection.insert(option) }
                } label: {
                    Text(option)
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(selection.contains(option) ? Color.cosmicVoid : Color.cosmicTextSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(selection.contains(option) ? Color.cosmicAmethyst : Color.cosmicStardust))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct TopoFlowLayout: Layout {
    let spacing: CGFloat
    let runSpacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { x = 0; y += rowH + runSpacing; rowH = 0 }
            rowH = max(rowH, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : maxX, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowH + runSpacing; rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Detail

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.cosmicCosmos.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(entry.createdAt, format: .dateTime.weekday(.wide).month().day().hour().minute())
                        .font(.cosmicCaptionEmphasis).tracking(1.0)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    detailCard("WHAT HAPPENED", body: entry.whatHappened)
                    bodyRegionsCard
                    detailCard("STORY YOU CREATED", body: entry.storyCreated)
                    patternCard
                    detailCard("WHAT I DID", body: entry.whatIDid)
                    detailCard("HIGHER ROUTE", body: entry.higherRoute)
                    detailCard("LEARNING", body: entry.learning)
                    moodCard
                }
                .padding(20).padding(.bottom, 40)
            }
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        HapticFeedbackService.shared.lightImpact(); showEdit = true
                    } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
            }
        }
        .sheet(isPresented: $showEdit) { JournalComposeView(entry: entry) }
        .alert("Delete this entry?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                JournalStore.shared.delete(entry.id)
                HapticFeedbackService.shared.success()
                dismiss()
            }
        } message: { Text("This cannot be undone.") }
    }

    private func detailCard(_ caption: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            tinyCaption(caption)
            Text(body.isEmpty ? "—" : body)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .detailCardChrome()
    }

    private var bodyRegionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            tinyCaption("BODY RESPONSE")
            if entry.bodyRegions.isEmpty && entry.bodyNotes.isEmpty {
                Text("—").font(.cosmicCallout).foregroundStyle(Color.cosmicTextPrimary)
            } else {
                if !entry.bodyRegions.isEmpty {
                    TopoFlowLayout(spacing: 6, runSpacing: 6) {
                        ForEach(entry.bodyRegions, id: \.self) { r in
                            Text(r)
                                .font(.cosmicLabel)
                                .foregroundStyle(Color.cosmicVoid)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color.cosmicAmethyst))
                        }
                    }
                }
                if !entry.bodyNotes.isEmpty {
                    Text(entry.bodyNotes)
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .detailCardChrome()
    }

    @ViewBuilder private var patternCard: some View {
        if let pid = entry.patternId, let p = TopoContentLoader.shared.pattern(id: pid) {
            NavigationLink { PatternDetailView(pattern: p) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    tinyCaption("PATTERN")
                    Text(p.name)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(p.summary)
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cosmicAmethyst.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var moodCard: some View {
        if let b = entry.moodBefore, let a = entry.moodAfter {
            HStack {
                tinyCaption("MOOD")
                Spacer()
                Text("\(b) → \(a)")
                    .font(.cosmicCalloutEmphasis).monospaced()
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
        }
    }

    private func tinyCaption(_ s: String) -> some View {
        Text(s)
            .font(.cosmicMicro).tracking(1.2)
            .foregroundStyle(Color.cosmicTextTertiary)
    }
}

private extension View {
    func detailCardChrome() -> some View {
        self.padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
    }
}

// MARK: - Insights

struct InsightsView: View {
    @StateObject private var journal = JournalStore.shared
    @StateObject private var pauseLog = PauseLogStore.shared

    private var patternCounts: [(name: String, count: Int, tint: Color)] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = journal.entries.filter { $0.createdAt >= cutoff }
        var buckets: [String: Int] = [:]
        for e in recent { if let pid = e.patternId { buckets[pid, default: 0] += 1 } }
        return buckets.compactMap { pid, count -> (String, Int, Color)? in
            guard let p = TopoContentLoader.shared.pattern(id: pid) else { return nil }
            return (p.name, count, planetTint(for: p.westernDrivers.first?.planet ?? ""))
        }
        .sorted { $0.1 > $1.1 }
        .map { (name: $0.0, count: $0.1, tint: $0.2) }
    }

    private var bodyRegionCounts: [(region: String, count: Int)] {
        var buckets: [String: Int] = [:]
        for e in journal.entries { for r in e.bodyRegions { buckets[r, default: 0] += 1 } }
        return buckets.map { (region: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    private var moodTrail: [(before: Int, after: Int)] {
        journal.entries.sorted { $0.createdAt < $1.createdAt }.suffix(10)
            .compactMap { e -> (Int, Int)? in
                guard let b = e.moodBefore, let a = e.moodAfter else { return nil }
                return (b, a)
            }
            .map { (before: $0.0, after: $0.1) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if journal.entries.isEmpty && pauseLog.entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text("Your insights compound with every entry. Start journaling.")
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                .padding(.top, 100)
            } else {
                VStack(spacing: 16) {
                    InsightsCard(title: "Pattern frequency", subtitle: "Last 30 days") {
                        patternBars
                    }
                    InsightsCard(title: "Body heat", subtitle: "All time") {
                        bodyHeat
                    }
                    InsightsCard(title: "Mood trend", subtitle: "Last 10 entries") {
                        if moodTrail.isEmpty {
                            emptyText("Log mood before/after to see trend.")
                        } else {
                            MoodSparkline(points: moodTrail).frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 40)
            }
        }
    }

    private func emptyText(_ s: String) -> some View {
        Text(s)
            .font(.cosmicFootnote)
            .foregroundStyle(Color.cosmicTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var patternBars: some View {
        if patternCounts.isEmpty {
            emptyText("No patterns logged yet.")
        } else {
            let maxCount = max(patternCounts.first?.count ?? 1, 1)
            VStack(spacing: 8) {
                ForEach(Array(patternCounts.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 10) {
                        Text(item.name)
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .frame(width: 110, alignment: .leading).lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.cosmicStardust).frame(height: 24)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.tint)
                                    .frame(width: max(geo.size.width * CGFloat(item.count) / CGFloat(maxCount), 4), height: 24)
                            }
                        }
                        .frame(height: 24)
                        Text("\(item.count)")
                            .font(.cosmicCaptionEmphasis).monospaced()
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder private var bodyHeat: some View {
        if bodyRegionCounts.isEmpty {
            emptyText("No body notes yet.")
        } else {
            let maxCount = max(bodyRegionCounts.first?.count ?? 1, 1)
            TopoFlowLayout(spacing: 6, runSpacing: 6) {
                ForEach(Array(bodyRegionCounts.enumerated()), id: \.offset) { _, item in
                    Text("\(item.region) \(item.count)")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.cosmicAmethyst
                            .opacity(max(0.15, Double(item.count) / Double(maxCount)))))
                }
            }
        }
    }
}

private struct InsightsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Text(subtitle.uppercased())
                    .font(.cosmicMicro).tracking(1.1)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
    }
}

private struct MoodSparkline: View {
    let points: [(before: Int, after: Int)]

    private func pts(_ values: [Int], in geo: GeometryProxy) -> [CGPoint] {
        let stepX = points.count > 1 ? geo.size.width / CGFloat(points.count - 1) : 0
        return values.enumerated().map { i, v in
            CGPoint(x: stepX * CGFloat(i), y: geo.size.height * (1 - CGFloat(v) / 100.0))
        }
    }

    private func line(_ p: [CGPoint], color: Color, width: CGFloat) -> some View {
        Path { path in
            guard let first = p.first else { return }
            path.move(to: first)
            for pt in p.dropFirst() { path.addLine(to: pt) }
        }
        .stroke(color, lineWidth: width)
    }

    private func dots(_ p: [CGPoint], color: Color, size: CGFloat) -> some View {
        ForEach(Array(p.enumerated()), id: \.offset) { _, pt in
            Circle().fill(color).frame(width: size, height: size).position(pt)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let beforePts = pts(points.map { $0.before }, in: geo)
            let afterPts = pts(points.map { $0.after }, in: geo)
            ZStack {
                Path { p in
                    for frac in [0.0, 0.5, 1.0] {
                        let y = geo.size.height * CGFloat(frac)
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.cosmicTextTertiary.opacity(0.18), lineWidth: 0.5)
                line(beforePts, color: .cosmicTextSecondary, width: 1.0)
                line(afterPts, color: .cosmicAmethyst, width: 1.5)
                dots(beforePts, color: .cosmicTextSecondary, size: 5)
                dots(afterPts, color: .cosmicAmethyst, size: 6)
            }
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 12) {
                    legendDot(.cosmicTextSecondary, "before")
                    legendDot(.cosmicAmethyst, "after")
                }
                .padding(.bottom, 4).padding(.leading, 4)
            }
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
    }
}

#Preview {
    JournalView()
}
