import SwiftUI

/// Wave 9 UX pass 2 — Move 3 (G8 endgame: Time Travel "March of Life").
///
/// A vertical replay-a-month selector. The user can scrub through every month
/// from their birth onwards and see a glanceable summary of the transits for
/// that window. Tapping a month feeds it back into Time Travel as the target
/// date, so the existing Cosmic Map and dasha wheel become the detail view.
///
/// Lightweight: no new backend call, no new model. The header summary is
/// inferred from a deterministic per-(month) descriptor so the timeline reads
/// like an autobiography even before the user taps in.
struct MarchOfLifeView: View {
    let birthDate: Date
    /// Called when the user picks a date — caller routes back into Time Travel.
    let onMonthSelected: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    private var months: [Date] {
        Self.months(from: birthDate, through: Date())
    }

    private var groupedByYear: [(year: Int, months: [Date])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: months, by: { calendar.component(.year, from: $0) })
        return grouped
            .sorted { $0.key > $1.key }
            .map { (year: $0.key, months: $0.value.sorted(by: >)) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Cosmic.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, Cosmic.Spacing.md)

                    ForEach(groupedByYear, id: \.year) { group in
                        Section(header: yearHeader(group.year)) {
                            ForEach(group.months, id: \.self) { month in
                                MonthRow(
                                    month: month,
                                    descriptor: Self.descriptor(for: month),
                                    isCurrentMonth: Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month)
                                )
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onMonthSelected(month)
                                    dismiss()
                                }
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
            }
            .background(Color.cosmicBackground)
            .navigationTitle("March of Life")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            Text("Every month since you arrived.")
                .font(.cosmicTitle3.italic())
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("Tap any month to scrub back into that window. Time Travel will load the sky as it was then.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
        )
    }

    private func yearHeader(_ year: Int) -> some View {
        HStack {
            Text(verbatim: String(year))
                .font(.cosmicHeadline.monospacedDigit())
                .foregroundStyle(Color.cosmicGold)
            Rectangle()
                .fill(Color.cosmicGold.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.cosmicBackground)
    }

    // MARK: - Month list helpers

    /// Generate the list of month starts from `from` (clamped to month start)
    /// up to and including the month containing `through`.
    private static func months(from: Date, through: Date) -> [Date] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .month, for: from)?.start,
              let end = calendar.dateInterval(of: .month, for: through)?.start else {
            return []
        }
        var result: [Date] = []
        var cursor = start
        // Hard guard: cap at ~120 years to keep the list bounded.
        let maxIterations = 12 * 120
        var iterations = 0
        while cursor <= end && iterations < maxIterations {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
            iterations += 1
        }
        return result
    }

    /// A stable, deterministic descriptor for each month so the timeline reads
    /// like an autobiography preview. Uses a small bank of named transits
    /// rotated by (year, month) hash — replace with a real transit lookup
    /// once the server-side endpoint lands (see brief §6a).
    static func descriptor(for month: Date) -> String {
        let calendar = Calendar.current
        let y = calendar.component(.year, from: month)
        let m = calendar.component(.month, from: month)
        let lines = [
            "Saturn moved through long-form work.",
            "Jupiter expanded a doorway you almost missed.",
            "Venus softened the room.",
            "Mercury asked you to revise — twice.",
            "Mars set down a stake.",
            "Rahu turned a private hunger outward.",
            "Ketu pruned what was no longer needed.",
            "The Moon held an old fear up to the light.",
            "The Sun reordered the season around you.",
            "A retrograde came to finish unspoken work.",
            "A new dasha began without fanfare.",
            "The sky was quiet. You did the work anyway."
        ]
        let idx = ((y &* 7) &+ (m &* 31)) % lines.count
        return lines[(idx + lines.count) % lines.count]
    }
}

// MARK: - Row

private struct MonthRow: View {
    let month: Date
    let descriptor: String
    let isCurrentMonth: Bool

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.md) {
            VStack(spacing: 2) {
                Circle()
                    .fill(isCurrentMonth ? Color.cosmicGold : Color.cosmicGold.opacity(0.35))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.cosmicGold.opacity(0.18))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Self.monthFormatter.string(from: month))
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    if isCurrentMonth {
                        Text("Now")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cosmicGold.opacity(0.2), in: Capsule())
                            .foregroundStyle(Color.cosmicGold)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Text(descriptor)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Self.monthFormatter.string(from: month)). \(descriptor)")
    }
}
