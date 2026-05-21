import SwiftUI

// MARK: - Pattern Library

struct PatternLibraryView: View {
    private let patterns = TopoContentLoader.shared.patterns
    private let activeNow = PatternMatcher.shared.topActive(limit: 3)

    @StateObject private var quota = ProQuotaManager.shared
    @State private var showingPaywall = false
    @State private var pendingPattern: Pattern?
    @AppStorage("hasAstronovaPro") private var hasPro: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                backdrop
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        if !activeNow.isEmpty {
                            activeNowSection
                        }
                        allPatternsSection
                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $pendingPattern) { pattern in
                PatternDetailView(pattern: pattern)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallVariantRouter(context: .general)
            }
        }
    }

    private func openPattern(_ pattern: Pattern) {
        if quota.canViewPatternDetail {
            quota.recordPatternView()
            pendingPattern = pattern
        } else {
            showingPaywall = true
        }
    }

    private var backdrop: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            LinearGradient(
                colors: [Color.cosmicAmethyst.opacity(0.16), Color.cosmicVoid],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Patterns")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Loops your chart runs by default.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
            if !hasPro {
                Text("Pro · 1 free pattern detail / week — \(quota.patternViewsUsedThisWeek)/\(ProQuotaManager.patternWeeklyLimit) used")
                    .font(.cosmicLabel)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
    }

    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("ACTIVE NOW")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeNow) { activation in
                        Button {
                            openPattern(activation.pattern)
                        } label: {
                            ActiveCard(activation: activation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var allPatternsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("ALL PATTERNS")
            VStack(spacing: 12) {
                ForEach(patterns) { pattern in
                    Button {
                        openPattern(pattern)
                    } label: {
                        PatternRow(pattern: pattern)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footer: some View {
        Text("PATTERN = STIMULUS + SCRIPT + NEED → ROUTE")
            .font(.cosmicMicro)
            .tracking(2.5)
            .foregroundStyle(Color.cosmicTextTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
    }
}

// MARK: - Library cards

private struct ActiveCard: View {
    let activation: PatternActivation
    private var tint: Color {
        planetTint(for: activation.pattern.westernDrivers.first { $0.role == "primary" }?.planet ?? "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(activation.pattern.name)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            ScoreBar(score: activation.score, tint: tint)
            Text(activation.reasons.first ?? "Default script available.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.3), lineWidth: 1))
    }
}

private struct ScoreBar: View {
    let score: Double
    let tint: Color
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.cosmicSurfaceSecondary)
                Capsule().fill(tint)
                    .frame(width: max(4, proxy.size.width * CGFloat(min(max(score, 0), 1))))
            }
        }
        .frame(height: 4)
    }
}

private struct PatternRow: View {
    let pattern: Pattern
    private var tint: Color {
        planetTint(for: pattern.westernDrivers.first { $0.role == "primary" }?.planet ?? "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(pattern.name)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer(minLength: 8)
                ActivationBadge(level: pattern.activationLevel)
            }
            Text(pattern.summary)
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let firstCue = pattern.detectionCues.first {
                Text("When fires: \(firstCue)")
                    .font(.cosmicLabel)
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Pattern Detail

struct PatternDetailView: View {
    let pattern: Pattern

    @StateObject private var journal = JournalStore.shared

    private var primaryWestern: String? {
        pattern.westernDrivers.first { $0.role == "primary" }?.planet
    }

    private var primaryVedic: String? {
        pattern.vedicDrivers.first { $0.role == "primary" }?.graha
    }

    private var tint: Color {
        planetTint(for: primaryWestern ?? "")
    }

    private var planet: ConsciousnessPlanet? {
        guard let id = primaryWestern?.lowercased() else { return nil }
        return TopoContentLoader.shared.planet(id: id)
    }

    private var currentLevel: Int {
        switch pattern.activationLevel {
        case .high:   return 1
        case .medium: return 2
        case .low:    return 3
        }
    }

    private var entries: [JournalEntry] {
        journal.entries(forPatternId: pattern.id)
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    loopCard
                    bodySignatureSection
                    consciousnessLadderSection
                    detectionCuesSection
                    journalSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pattern.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            ActivationBadge(level: pattern.activationLevel)
            Text(driverCaption)
                .font(.cosmicCaptionEmphasis)
                .tracking(0.4)
                .foregroundStyle(tint)
            Text(pattern.summary)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(tint.opacity(0.25), lineWidth: 1))
    }

    private var driverCaption: String {
        let west = primaryWestern?.capitalized ?? "—"
        let ved = primaryVedic?.capitalized ?? "—"
        return "DRIVER: \(west) · \(ved)"
    }

    // MARK: The Loop

    private var loopCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("THE LOOP")
                .padding(.bottom, 12)
            VStack(spacing: 14) {
                LoopRow(caption: "STIMULUS", text: pattern.loop.stimulus)
                LoopRow(caption: "DEFAULT SCRIPT", text: pattern.loop.defaultScript)
                LoopRow(caption: "HIDDEN NEED", text: pattern.loop.hiddenNeed)
                LoopRow(caption: "LOW CONSCIOUSNESS", text: pattern.loop.lowConsciousnessOutput)
                LoopRow(caption: "HIGH CONSCIOUSNESS", text: pattern.loop.highConsciousnessRoute)
                LoopRow(
                    caption: "OPTIMAL ACTION",
                    text: pattern.loop.optimalAction,
                    emphasis: true,
                    tint: tint
                )
            }
        }
    }

    // MARK: Body signature

    private var bodySignatureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("BODY SIGNATURE")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(pattern.bodySignature, id: \.self) { BulletLine(text: $0) }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        }
    }

    // MARK: Consciousness ladder

    @ViewBuilder
    private var consciousnessLadderSection: some View {
        if let planet {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("CONSCIOUSNESS LADDER · \(planet.westernName.uppercased())")
                VStack(spacing: 0) {
                    ForEach(planet.levels) { level in
                        LadderRow(level: level, tint: tint, isCurrent: level.level == currentLevel)
                        if level.level != planet.levels.last?.level {
                            Divider().background(Color.cosmicSurfaceSecondary)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.cosmicSurface))
            }
        }
    }

    // MARK: Detection cues

    private var detectionCuesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("DETECTION CUES")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(pattern.detectionCues, id: \.self) { BulletLine(text: $0) }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        }
    }

    // MARK: Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("YOUR JOURNAL ENTRIES")
            if entries.isEmpty {
                Text("No entries tagged with this pattern yet.")
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface.opacity(0.7)))
            } else {
                VStack(spacing: 8) {
                    ForEach(entries) { JournalRow(entry: $0) }
                }
            }
        }
    }
}

// MARK: - Detail subcomponents

private struct LoopRow: View {
    let caption: String
    let text: String
    var emphasis: Bool = false
    var tint: Color = .clear
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if emphasis {
                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(tint).frame(width: 4)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.cosmicMicro)
                    .tracking(1.6)
                    .foregroundStyle(emphasis ? tint : Color.cosmicTextTertiary)
                Text(text)
                    .font(.system(size: emphasis ? 17 : 15, weight: emphasis ? .semibold : .regular))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(emphasis ? tint.opacity(0.08) : Color.cosmicSurface))
    }
}

private struct LadderRow: View {
    let level: ConsciousnessLevel
    let tint: Color
    let isCurrent: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(level.level)")
                .font(.system(size: 32, weight: .regular, design: .monospaced))
                .foregroundStyle(isCurrent ? tint : Color.cosmicTextTertiary)
                .frame(width: 36, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(level.name)
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    if isCurrent {
                        Image(systemName: "pin.fill")
                            .font(.cosmicLabel)
                            .foregroundStyle(tint)
                    }
                    Spacer(minLength: 0)
                }
                if !level.keywords.isEmpty {
                    Text(level.keywords.joined(separator: " · "))
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(tint.opacity(0.85))
                }
                Text(level.bodyCue)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(level.behavior)
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? tint.opacity(0.10) : Color.clear)
    }
}

private struct JournalRow: View {
    let entry: JournalEntry
    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(Self.dateFmt.string(from: entry.createdAt).uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.cosmicTextTertiary)
                .frame(width: 56, alignment: .leading)
            Text(entry.whatHappened.isEmpty ? "—" : truncate(entry.whatHappened, max: 100))
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.cosmicSurface))
    }
    private func truncate(_ s: String, max: Int) -> String {
        s.count <= max ? s : String(s.prefix(max)) + "…"
    }
}

// MARK: - Shared subcomponents

private struct ActivationBadge: View {
    let level: Pattern.ActivationLevel
    var body: some View {
        Text(label)
            .font(.cosmicMicro)
            .tracking(1.6)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(background))
    }
    private var label: String {
        switch level { case .high: return "HIGH"; case .medium: return "MEDIUM"; case .low: return "LOW" }
    }
    private var background: Color {
        switch level {
        case .high:   return Color.planetMars.opacity(0.25)
        case .medium: return Color.cosmicGold.opacity(0.22)
        case .low:    return Color.cosmicTextTertiary.opacity(0.18)
        }
    }
    private var foreground: Color {
        switch level {
        case .high:   return Color.planetMars
        case .medium: return Color.cosmicGold
        case .low:    return Color.cosmicTextSecondary
        }
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.cosmicMicro)
            .tracking(2.0)
            .foregroundStyle(Color.cosmicTextTertiary)
    }
}

private struct BulletLine: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·")
                .font(.cosmicFootnoteEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(text)
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    PatternLibraryView()
}
