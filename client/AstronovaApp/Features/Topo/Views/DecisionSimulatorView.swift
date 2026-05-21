import SwiftUI

// MARK: - Shared Styling

private extension Color {
    static var topoCard: Color { Color.cosmicSurface }
}

private struct CaptionStyle: ViewModifier {
    var tint: Color = Color.cosmicTextSecondary
    func body(content: Content) -> some View {
        content
            .font(.cosmicLabel)
            .tracking(1.2)
            .foregroundStyle(tint)
    }
}

private extension View {
    func topoCaption(_ tint: Color = Color.cosmicTextSecondary) -> some View {
        modifier(CaptionStyle(tint: tint))
    }

    func topoCardBackground(_ fill: Color = Color.cosmicSurface, radius: CGFloat = 12) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
    }
}

@ViewBuilder
private func topoField<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(label.uppercased()).topoCaption()
        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

@ViewBuilder
private func primaryButton(_ title: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(.cosmicBodyEmphasis)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .topoCardBackground(enabled ? Color.cosmicAccent : Color.cosmicSurface, radius: 14)
            .foregroundStyle(enabled ? Color.cosmicVoid : Color.cosmicTextTertiary)
    }
    .disabled(!enabled)
    .buttonStyle(.plain)
}

// MARK: - Decision Simulator Hub

struct DecisionSimulatorView: View {
    @StateObject private var decisionStore = DecisionStore.shared
    @StateObject private var ruleStore = NavigationRuleStore.shared
    @StateObject private var quota = ProQuotaManager.shared
    @AppStorage("hasAstronovaPro") private var hasPro: Bool = false
    @State private var showCompose = false
    @State private var showingPaywall = false
    @State private var pendingResult: Decision?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    primaryCTA
                    recentDecisionsSection
                    rulesSection
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color.cosmicVoid.ignoresSafeArea())
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCompose) {
                DecisionComposeView { pendingResult = $0 }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallVariantRouter(context: .general)
            }
            .navigationDestination(for: Decision.self) { DecisionResultView(decision: $0) }
            .navigationDestination(isPresented: Binding(
                get: { pendingResult != nil },
                set: { if !$0 { pendingResult = nil } }
            )) {
                if let d = pendingResult { DecisionResultView(decision: d) }
            }
        }
        .tint(Color.cosmicAccent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Decide")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Decisions under pressure, with the data.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryCTA: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                HapticFeedbackService.shared.mediumImpact()
                if quota.canRunDecision {
                    showCompose = true
                } else {
                    showingPaywall = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.cosmicHeadline)
                    Text("New Decision").font(.cosmicBodyEmphasis)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .topoCardBackground(Color.cosmicAccent, radius: 14)
                .foregroundStyle(Color.cosmicVoid)
            }
            .buttonStyle(.plain)

            if !hasPro {
                Text("\(quota.decisionsRemaining) free decisions left this month")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var recentDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Decisions".uppercased()).topoCaption()
            let recent = decisionStore.recent()
            if recent.isEmpty {
                Text("No decisions yet. Run your first simulation.")
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(recent) { decision in
                        NavigationLink(value: decision) {
                            DecisionRow(decision: decision)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Navigation Algorithm".uppercased()).topoCaption()
                Spacer()
                NavigationLink {
                    NavigationRulesView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.cosmicFootnoteEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .padding(8)
                        .background(Circle().fill(Color.cosmicSurface))
                }
                .buttonStyle(.plain)
            }
            let top = Array(ruleStore.activeRules.prefix(3))
            if top.isEmpty {
                Text("Your rules will appear here. Add the first one in Navigation Algorithm.")
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(top) { rule in
                        Text("› \(rule.text)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextPrimary.opacity(0.85))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

// MARK: - Decision Row

private struct DecisionRow: View {
    let decision: Decision

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d · h:mm a"
        return f.string(from: decision.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateLabel)
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.cosmicLabel)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            Text(decision.promptText)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(decision.decisionClass.label.uppercased())
                .font(.cosmicLabel)
                .tracking(0.8)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .topoCardBackground()
    }
}

// MARK: - Decision Compose

struct DecisionComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var promptText: String = ""
    @State private var decisionClass: Decision.DecisionClass = .career
    @State private var timeHorizon: Decision.TimeHorizon = .days
    @State private var reversibility: Decision.Reversibility = .medium
    @State private var inclination: Decision.Inclination = .unclear
    @State private var mood: Double = 50

    var onCommit: (Decision) -> Void

    private var canRun: Bool {
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topoField("What's the decision?") {
                        ZStack(alignment: .topLeading) {
                            if promptText.isEmpty {
                                Text("Type the call you're facing.")
                                    .font(.cosmicCallout)
                                    .foregroundStyle(Color.cosmicTextTertiary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                            }
                            TextEditor(text: $promptText)
                                .font(.cosmicCallout)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(minHeight: 96)
                        }
                        .topoCardBackground()
                    }

                    topoField("Class") {
                        Picker("", selection: $decisionClass) {
                            ForEach(Decision.DecisionClass.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                    }

                    topoField("Time horizon") {
                        Picker("", selection: $timeHorizon) {
                            ForEach(Decision.TimeHorizon.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                    }

                    topoField("Reversibility") {
                        Picker("", selection: $reversibility) {
                            ForEach(Decision.Reversibility.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                    }

                    topoField("Lean") {
                        Picker("", selection: $inclination) {
                            ForEach(Decision.Inclination.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                    }

                    topoField("Mood — \(Int(mood))") {
                        Slider(value: $mood, in: 0...100, step: 1).tint(Color.cosmicAccent)
                    }

                    primaryButton("Run simulation", enabled: canRun, action: run)

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color.cosmicVoid.ignoresSafeArea())
            .navigationTitle("New Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
        }
        .tint(Color.cosmicAccent)
    }

    @MainActor
    private func run() {
        guard canRun else { return }
        var decision = Decision(
            id: UUID(),
            createdAt: Date(),
            promptText: promptText.trimmingCharacters(in: .whitespacesAndNewlines),
            decisionClass: decisionClass,
            timeHorizon: timeHorizon,
            reversibility: reversibility,
            userInclination: inclination,
            moodAtInput: Int(mood),
            output: nil
        )
        decision.output = DecisionEngine.shared.simulate(decision)
        ProQuotaManager.shared.recordDecisionRun()
        DecisionStore.shared.add(decision)
        HapticFeedbackService.shared.success()
        onCommit(decision)
        dismiss()
    }
}

// MARK: - Decision Result

struct DecisionResultView: View {
    let decision: Decision
    @State private var showSaveRule = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let output = decision.output {
                    promptHeader
                    axisCard("Current Weather", body: output.currentWeather)
                    defaultPatternCard(output)
                    axisCard("Risk", body: output.risk, tint: Color.cosmicError)
                    axisCard("Opportunity", body: output.opportunity, tint: Color.cosmicSuccess)
                    bestRouteCard(text: output.bestRoute, patternId: output.citedPatternIds.first)
                    questionCard(output.questionToAnswer)
                    saveAsRuleButton
                    footer(output)
                } else {
                    Text("Output missing — re-run.")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 40)
                }
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Decision")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSaveRule) {
            NavigationRuleEditView(prefilledText: decision.output?.bestRoute ?? "")
        }
    }

    private var promptHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(decision.decisionClass.label.uppercased()).topoCaption(Color.cosmicTextTertiary)
            Text(decision.promptText)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
    }

    private func axisCard(_ caption: String, body: String, tint: Color = Color.cosmicTextSecondary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption.uppercased()).topoCaption(tint)
            Text(body)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .topoCardBackground()
    }

    private func defaultPatternCard(_ output: DecisionOutput) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR DEFAULT PATTERN").topoCaption()
            Text(output.defaultPattern)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let pid = output.citedPatternIds.first,
               let pattern = TopoContentLoader.shared.pattern(id: pid) {
                Text(pattern.name)
                    .font(.cosmicFootnoteEmphasis)
                    .foregroundStyle(Color.cosmicAccent)
                    .underline()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .topoCardBackground()
    }

    private func bestRouteCard(text: String, patternId: String?) -> some View {
        let tint: Color = {
            guard let pid = patternId,
                  let p = TopoContentLoader.shared.pattern(id: pid) else {
                return Color.cosmicGold
            }
            let planet = p.westernDrivers.compactMap(\.planet).first
                ?? p.vedicDrivers.compactMap(\.graha).first
            return planet.map { planetTint(for: $0) } ?? Color.cosmicGold
        }()
        return HStack(alignment: .top, spacing: 12) {
            Rectangle().fill(tint).frame(width: 3).clipShape(Capsule())
            VStack(alignment: .leading, spacing: 8) {
                Text("BEST ROUTE").topoCaption()
                Text(text)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .topoCardBackground()
    }

    private func questionCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUESTION TO ANSWER").topoCaption(Color.cosmicAmethyst)
            Text(text)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .topoCardBackground(Color.cosmicAmethyst.opacity(0.15))
    }

    private var saveAsRuleButton: some View {
        Button {
            HapticFeedbackService.shared.selection()
            showSaveRule = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bookmark").font(.cosmicCalloutEmphasis)
                Text("Save as rule").font(.cosmicCalloutEmphasis)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.cosmicAccent, lineWidth: 1)
            )
            .foregroundStyle(Color.cosmicAccent)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private func footer(_ output: DecisionOutput) -> some View {
        let drivers = output.citedTransitDrivers.isEmpty
            ? "—"
            : output.citedTransitDrivers.joined(separator: ", ")
        return Text("DRIVERS: \(drivers)")
            .font(.cosmicMicro)
            .tracking(1.0)
            .foregroundStyle(Color.cosmicTextTertiary)
            .padding(.top, 8)
    }
}

// MARK: - Navigation Rules List

struct NavigationRulesView: View {
    @StateObject private var store = NavigationRuleStore.shared
    @State private var showAdd = false
    @State private var editingRule: NavigationRule?

    private var sortedRules: [NavigationRule] {
        store.rules.sorted { lhs, rhs in
            if lhs.active != rhs.active { return lhs.active && !rhs.active }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var sumInvoked: Int { store.rules.reduce(0) { $0 + $1.timesInvoked } }
    private var sumFollowed: Int { store.rules.reduce(0) { $0 + $1.timesFollowed } }

    var body: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            if store.rules.isEmpty {
                emptyState
            } else {
                List {
                    if sumInvoked > 0 {
                        Text("\(store.activeRules.count) ACTIVE RULES · \(sumFollowed)/\(sumInvoked) KEPT")
                            .topoCaption(Color.cosmicTextTertiary)
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    ForEach(sortedRules) { rule in
                        RuleRow(
                            rule: rule,
                            onToggle: { store.toggleActive(rule.id) },
                            onTap: { editingRule = rule }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.delete(rule.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Navigation Algorithm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicAccent)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationRuleEditView(prefilledText: "")
        }
        .sheet(item: $editingRule) { rule in
            NavigationRuleEditView(prefilledText: rule.text, existingRule: rule)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(Color.cosmicTextTertiary)
            Text("No rules yet.")
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Tap + to write your first.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding()
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: NavigationRule
    let onToggle: () -> Void
    let onTap: () -> Void

    private var linkedPatternName: String? {
        guard let pid = rule.triggerPatternId else { return nil }
        return TopoContentLoader.shared.pattern(id: pid)?.name
    }

    private var stars: String {
        String(repeating: "★", count: max(0, min(rule.confidence, 5)))
    }

    private var captionText: String {
        var parts: [String] = [rule.triggerContext.label]
        if let name = linkedPatternName { parts.append("linked to \(name)") }
        parts.append("confidence \(stars)")
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("› \(rule.text)")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(rule.active ? Color.cosmicTextPrimary : Color.cosmicTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(captionText)
                        .font(.cosmicLabel)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: Binding(
                    get: { rule.active },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(Color.cosmicAccent)
            }
            .padding(12)
            .topoCardBackground(Color.cosmicSurface.opacity(rule.active ? 1.0 : 0.5), radius: 10)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: - Rule Edit

struct NavigationRuleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var triggerContext: NavigationRule.TriggerContext
    @State private var triggerPatternId: String?
    @State private var confidence: Int
    @State private var decayDate: Date

    private let existingRule: NavigationRule?

    init(prefilledText: String, existingRule: NavigationRule? = nil) {
        self.existingRule = existingRule
        _text = State(initialValue: existingRule?.text ?? prefilledText)
        _triggerContext = State(initialValue: existingRule?.triggerContext ?? .generic)
        _triggerPatternId = State(initialValue: existingRule?.triggerPatternId)
        _confidence = State(initialValue: existingRule?.confidence ?? 3)
        _decayDate = State(initialValue: existingRule?.decayReviewDate ?? Date().addingTimeInterval(60 * 60 * 24 * 90))
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var linkedPatternName: String {
        if let pid = triggerPatternId, let p = TopoContentLoader.shared.pattern(id: pid) {
            return p.name
        }
        return "none"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topoField("Rule") {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("When [trigger], I [action].")
                                    .font(.cosmicCallout)
                                    .foregroundStyle(Color.cosmicTextTertiary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                            }
                            TextEditor(text: $text)
                                .font(.cosmicCallout)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(minHeight: 84)
                        }
                        .topoCardBackground()
                    }

                    topoField("Trigger context") {
                        Picker("", selection: $triggerContext) {
                            ForEach(NavigationRule.TriggerContext.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                    }

                    topoField("Linked pattern") {
                        Menu {
                            Button("None") { triggerPatternId = nil }
                            ForEach(TopoContentLoader.shared.patterns) { p in
                                Button(p.name) { triggerPatternId = p.id }
                            }
                        } label: {
                            HStack {
                                Text(linkedPatternName)
                                    .font(.cosmicCallout)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)
                            }
                            .padding(14)
                            .topoCardBackground()
                        }
                    }

                    topoField("Confidence") {
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    HapticFeedbackService.shared.selection()
                                    confidence = star
                                } label: {
                                    Image(systemName: star <= confidence ? "star.fill" : "star")
                                        .font(.cosmicTitle2)
                                        .foregroundStyle(star <= confidence ? Color.cosmicGold : Color.cosmicTextTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }

                    topoField("Decay review") {
                        DatePicker("", selection: $decayDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Color.cosmicAccent)
                    }

                    primaryButton(existingRule == nil ? "Save rule" : "Update rule",
                                  enabled: canSave, action: save)

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color.cosmicVoid.ignoresSafeArea())
            .navigationTitle(existingRule == nil ? "New Rule" : "Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
        }
        .tint(Color.cosmicAccent)
    }

    @MainActor
    private func save() {
        guard canSave else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = existingRule {
            var updated = existing
            updated.text = trimmed
            updated.triggerContext = triggerContext
            updated.triggerPatternId = triggerPatternId
            updated.confidence = confidence
            updated.decayReviewDate = decayDate
            NavigationRuleStore.shared.update(updated)
        } else {
            let rule = NavigationRule(
                text: trimmed,
                triggerPatternId: triggerPatternId,
                triggerContext: triggerContext,
                source: .manual,
                confidence: confidence,
                decayReviewDate: decayDate
            )
            NavigationRuleStore.shared.add(rule)
        }
        HapticFeedbackService.shared.success()
        dismiss()
    }
}

#Preview {
    DecisionSimulatorView()
}
