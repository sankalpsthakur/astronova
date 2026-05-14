//
//  CosmicDiaryView.swift
//  AstronovaApp
//
//  Wave 10 — the user's chronological cosmic autobiography. Today's reading
//  sits at the top (collapsed if already opened). Below, every past reading
//  is grouped by month and tappable for the full text plus the user's note.
//

import SwiftUI

struct CosmicDiaryView: View {
    @StateObject private var store = CosmicDiaryStore.shared
    @State private var showFutureLetters = false
    @State private var selectedEntry: DiaryEntry?
    @State private var todayExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
                header

                if let today = store.todaysEntry() {
                    todaySection(today)
                } else {
                    emptyTodayCard
                }

                pastSection
            }
            .padding(.horizontal, Cosmic.Spacing.m)
            .padding(.top, Cosmic.Spacing.s)
            .padding(.bottom, Cosmic.Spacing.xxl)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Cosmic Diary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFutureLetters = true
                } label: {
                    Image(systemName: "envelope.open")
                        .foregroundStyle(Color.cosmicGold)
                }
                .accessibilityLabel("Future letters")
            }
        }
        .sheet(isPresented: $showFutureLetters) {
            NavigationStack { FutureLetterView() }
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack { DiaryEntryDetailView(entry: entry) }
        }
        .task {
            store.migrateFromLegacyCacheIfNeeded()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your cosmic autobiography")
                .font(.cosmicTitle)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Every reading you open is logged here. Scroll back to find the sky you were under.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }

    private func todaySection(_ entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text("TODAY")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicGold)
                .tracking(2)

            Button {
                withAnimation(.cosmicSpring) { todayExpanded.toggle() }
            } label: {
                DiaryEntryRow(entry: entry, expanded: todayExpanded)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyTodayCard: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text("TODAY")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicGold)
                .tracking(2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Today's reading hasn't been opened yet.")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text("Open the Discover tab. When you read today's reading, it lands here.")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding(Cosmic.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        }
    }

    private var pastSection: some View {
        let groups = pastGroups()
        return Group {
            if groups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The archive is empty for now.")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text("Come back tomorrow — and the day after.")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .padding(.top, Cosmic.Spacing.m)
            } else {
                ForEach(groups, id: \.label) { group in
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text(group.label.uppercased())
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .tracking(2)
                            .padding(.top, Cosmic.Spacing.s)
                        ForEach(group.entries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                DiaryEntryRow(entry: entry, expanded: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    /// Past entries = every entry except today's.
    private func pastGroups() -> [(label: String, entries: [DiaryEntry])] {
        let todayKey = CosmicDiaryStore.dateKey(for: Date())
        return store.entriesGroupedByMonth().compactMap { group in
            let filtered = group.entries.filter { $0.date != todayKey }
            return filtered.isEmpty ? nil : (label: group.label, entries: filtered)
        }
    }
}

// MARK: - Row

struct DiaryEntryRow: View {
    let entry: DiaryEntry
    let expanded: Bool

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: entry.dateValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dateLabel)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                DepthBadge(depth: entry.depth)
            }

            if let headline = entry.headline, !headline.isEmpty {
                Text(headline)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .italic()
            }

            if expanded {
                expandedBody
            } else {
                Text(collapsedSummary)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(3)
            }

            if let note = entry.userNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.cosmicGold)
                    Text(note)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(Cosmic.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                .strokeBorder(
                    entry.depth == .epiphany ? Color.cosmicGold.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var collapsedSummary: String {
        if let extended = entry.extendedBody, !extended.isEmpty { return extended }
        return entry.focus
    }

    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let transit = entry.transitNote, !transit.isEmpty {
                Text(transit)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
            }
            tileRow("Focus", entry.focus)
            tileRow("Relationships", entry.relationships)
            tileRow("Energy", entry.energy)
            if let extended = entry.extendedBody, !extended.isEmpty {
                Text(extended)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .padding(.top, 4)
            }
            if let prompt = entry.reflectionPrompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.cosmicCaption)
                    .italic()
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .padding(.top, 4)
            }
        }
    }

    private func tileRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .frame(width: 100, alignment: .leading)
            Text(body)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Depth badge

struct DepthBadge: View {
    let depth: DailyReadingDepth

    var body: some View {
        let (label, color): (String, Color) = {
            switch depth {
            case .epiphany: return ("epiphany", .cosmicGold)
            case .depth: return ("depth", .cosmicPrimary)
            case .general: return ("daily", .cosmicTextTertiary)
            }
        }()
        Text(label)
            .font(.cosmicMicro)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Entry detail (sheet)

/// Wave 11 polish — Move 3.
///
/// A long-form, calm detail page for a single diary entry. The original
/// implementation rendered an expanded `DiaryEntryRow` which is good for the
/// list but too dense for solo reading. The polished layout:
///  - Serif date heading (system serif — designed for legibility, no licensing).
///  - DepthBadge.
///  - Headline + reading text in body typography with line-height ~1.7 and
///    paragraph spacing.
///  - User note editor (preserved from Wave 10).
///  - Celestial illustration placeholder: `moon.stars` SF Symbol.
///    Designer spec lives in `// DESIGNER:` comments in the body — the final
///    illustration should be a custom SVG/PDF at 160×160 with stroke=1px in
///    cosmicGold, sitting at 60% opacity.
///  - "What was happening cosmically:" footer that surfaces `transitNote`
///    when present.
struct DiaryEntryDetailView: View {
    let entry: DiaryEntry
    @State private var note: String
    @StateObject private var store = CosmicDiaryStore.shared
    @Environment(\.dismiss) private var dismiss

    init(entry: DiaryEntry) {
        self.entry = entry
        self._note = State(initialValue: entry.userNote ?? "")
    }

    private static let detailDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE\nMMMM d, yyyy"
        f.locale = Locale.current
        return f
    }()

    /// Split the long-form text into paragraphs and render each with proper
    /// spacing. Falls back to the focus line if no extended body is present.
    private var readingParagraphs: [String] {
        let source = [entry.headline, entry.extendedBody, entry.horoscopeText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
        guard let text = source, !text.isEmpty else { return [entry.focus] }
        return text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                header
                readingBody
                noteEditor
                celestialIllustration
                cosmicFooter
            }
            .padding(.horizontal, Cosmic.Spacing.lg)
            .padding(.top, Cosmic.Spacing.lg)
            .padding(.bottom, Cosmic.Spacing.xxl)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle(entry.sign)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    store.updateNote(for: entry.id, note: note)
                    dismiss()
                }
                .foregroundStyle(Color.cosmicGold)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text(Self.detailDateFormatter.string(from: entry.dateValue))
                .font(.system(.largeTitle, design: .serif).weight(.regular))
                .foregroundStyle(Color.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            DepthBadge(depth: entry.depth)
        }
    }

    private var readingBody: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            ForEach(Array(readingParagraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    // Line-height multiplier ~1.7 (target spec): we add raw
                    // leading on top of the default to land near 1.7×.
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text("YOUR NOTE")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
                .tracking(2)
            TextEditor(text: $note)
                .font(.cosmicBody)
                .frame(minHeight: 140)
                .padding(Cosmic.Spacing.sm)
                .background(Color.cosmicSurface)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
                .scrollContentBackground(.hidden)
        }
    }

    /// DESIGNER: replace with a custom illustration.
    /// - Target: 160×160 SVG/PDF, 1px stroke in cosmicGold at 60% opacity.
    /// - Concept: a hand-drawn lunar crescent with three small stars,
    ///   matching the Teenage-Engineering line-art motif used elsewhere.
    /// - Behavior: tap → no-op for now; future: link to the natal moon's
    ///   placement on that day.
    private var celestialIllustration: some View {
        VStack {
            Image(systemName: "moon.stars")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.cosmicGold.opacity(0.6))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Cosmic.Spacing.lg)
    }

    @ViewBuilder
    private var cosmicFooter: some View {
        if let transit = entry.transitNote, !transit.isEmpty {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                Text("What was happening cosmically")
                    .font(.cosmicCaption.weight(.semibold))
                    .foregroundStyle(Color.cosmicGold)
                    .tracking(0.5)
                Text(transit)
                    .font(.cosmicCaption.italic())
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Cosmic.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cosmicSurface.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        }
    }
}
