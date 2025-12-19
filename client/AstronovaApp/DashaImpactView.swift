import SwiftUI

/// Impact Bars showing career, relationships, health, spiritual scores
/// with smooth animations < 600ms and comparison features
struct DashaImpactView: View {
    let impactScores: DashaCompleteResponse.ImpactScores
    let tone: String
    let toneDescription: String
    let comparisonScores: DashaCompleteResponse.ImpactScores?

    @State private var animatedValues: [String: CGFloat] = [:]
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let impactAreas: [(key: String, label: String, icon: String, color: Color)] = [
        ("career", "Career", "briefcase.fill", .blue),
        ("relationships", "Relationships", "heart.fill", .pink),
        ("health", "Health", "heart.circle.fill", .green),
        ("spiritual", "Spiritual", "sparkles", .purple),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tone indicator
            HStack(spacing: 12) {
                ToneIndicator(tone: tone)

                VStack(alignment: .leading, spacing: 2) {
                    Text(toneLabel(tone))
                        .font(.headline)
                        .foregroundStyle(toneColor(tone))

                    Text(toneDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Impact bars
            VStack(spacing: 12) {
                ForEach(impactAreas, id: \.key) { area in
                    ImpactBarRow(
                        label: area.label,
                        icon: area.icon,
                        color: area.color,
                        value: scoreFor(area.key, in: impactScores),
                        animatedValue: animatedValues[area.key] ?? 0,
                        comparisonValue: comparisonScores.map { scoreFor(area.key, in: $0) }
                    )
                }
            }
        }
        .onAppear {
            animateValues()
        }
        .onChange(of: impactScores) { _, _ in
            animateValues()
        }
    }

    private func scoreFor(_ key: String, in scores: DashaCompleteResponse.ImpactScores) -> Double {
        switch key {
        case "career": return scores.career
        case "relationships": return scores.relationships
        case "health": return scores.health
        case "spiritual": return scores.spiritual
        default: return 0
        }
    }

    private func animateValues() {
        // Reset to 0
        for area in impactAreas {
            animatedValues[area.key] = 0
        }

        // Animate to actual values with stagger
        let duration = reduceMotion ? 0.1 : 0.5
        let stagger = reduceMotion ? 0 : 0.08

        for (index, area) in impactAreas.enumerated() {
            let delay = Double(index) * stagger
            let targetValue = CGFloat(scoreFor(area.key, in: impactScores))

            withAnimation(.spring(response: duration, dampingFraction: 0.75).delay(delay)) {
                animatedValues[area.key] = targetValue
            }
        }
    }

    private func toneLabel(_ tone: String) -> String {
        tone.capitalized + " Period"
    }

    private func toneColor(_ tone: String) -> Color {
        switch tone.lowercased() {
        case "supportive", "positive": return .green
        case "mixed": return .orange
        case "challenging": return .red
        case "transformative": return .purple
        default: return .gray
        }
    }
}

// MARK: - Tone Indicator

struct ToneIndicator: View {
    let tone: String

    var body: some View {
        ZStack {
            Circle()
                .fill(toneColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: toneIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(toneColor)
        }
    }

    private var toneColor: Color {
        switch tone.lowercased() {
        case "supportive", "positive": return .green
        case "mixed": return .orange
        case "challenging": return .red
        case "transformative": return .purple
        default: return .gray
        }
    }

    private var toneIcon: String {
        switch tone.lowercased() {
        case "supportive": return "checkmark.circle.fill"
        case "positive": return "arrow.up.circle.fill"
        case "mixed": return "circle.lefthalf.filled"
        case "challenging": return "exclamationmark.triangle.fill"
        case "transformative": return "arrow.triangle.2.circlepath"
        default: return "circle.fill"
        }
    }
}

// MARK: - Impact Bar Row

struct ImpactBarRow: View {
    let label: String
    let icon: String
    let color: Color
    let value: Double
    let animatedValue: CGFloat
    let comparisonValue: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)

                if let comparison = comparisonValue {
                    DeltaIndicator(delta: value - comparison)
                }
            }

            // Bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(min(animatedValue / 10.0, 1.0)))

                    // Comparison indicator if present
                    if let comparison = comparisonValue {
                        ComparisonMarker(
                            position: CGFloat(comparison / 10.0) * geometry.size.width,
                            isHigher: value > comparison
                        )
                    }
                }
            }
            .frame(height: 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: "%.1f", value)) out of 10")
    }
}

// MARK: - Delta Indicator

struct DeltaIndicator: View {
    let delta: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2.weight(.bold))

            Text(String(format: "%.1f", abs(delta)))
                .font(.caption2.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(delta >= 0 ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill((delta >= 0 ? Color.green : Color.red).opacity(0.15))
        )
    }
}

// MARK: - Comparison Marker

struct ComparisonMarker: View {
    let position: CGFloat
    let isHigher: Bool

    var body: some View {
        Rectangle()
            // Semantic colors: green when current is higher (improvement), red when lower
            .fill(isHigher ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
            .frame(width: 2)
            .offset(x: position)
    }
}

// MARK: - Detail Card View

struct DashaDetailCardView: View {
    let period: DashaCompleteResponse.DashaDetails.Period
    let level: String
    let strength: DashaCompleteResponse.ImpactAnalysis.StrengthData?
    let keywords: [String]
    let explanation: String?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(period.lord)
                            .font(.largeTitle.weight(.bold))

                        Text(level.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Label("Duration", systemImage: "calendar")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatDate(period.start))
                                .font(.subheadline.weight(.medium))
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("End")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatDate(period.end))
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }

                // Strength
                if let strength = strength {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Planetary Strength", systemImage: "star.fill")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(strength.strengthLabel.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .font(.subheadline.weight(.semibold))

                                Text("Dignity: \(strength.dignity.capitalized)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .trim(from: 0, to: CGFloat(strength.overallScore / 100.0))
                                    .stroke(strengthColor(strength.strengthLabel), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))

                                Text(String(format: "%.0f", strength.overallScore))
                                    .font(.title3.weight(.bold).monospacedDigit())
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Keywords
                if !keywords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Key Themes", systemImage: "tag.fill")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(keywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                }

                // Explanation
                if let explanation = explanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Understanding This Period", systemImage: "book.fill")
                            .font(.headline)

                        Text(explanation)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: isoString) else { return isoString }

        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func strengthColor(_ label: String) -> Color {
        switch label.lowercased() {
        case "very_strong": return .green
        case "strong": return .blue
        case "moderate": return .orange
        case "weak": return .red
        default: return .gray
        }
    }
}

// MARK: - Flow Layout for Keywords

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.subviewIndices {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth, !currentRow.subviewIndices.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }

            currentRow.subviewIndices.append(index)
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }

        if !currentRow.subviewIndices.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var subviewIndices: [Int] = []
        var height: CGFloat = 0
    }
}
