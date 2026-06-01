import SwiftUI

// MARK: - ContextPriorsStepView

/// Real-world priors step — collects situational context tags and free-text
/// for the Bayesian prediction engine. Without these, predictions lack
/// grounding in the user's actual circumstances.
struct ContextPriorsStepView: View {
    @Binding var selectedTags: [String]
    @Binding var freeTextContext: String

    @State private var animateTags = false
    @FocusState private var isTextFieldFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Tag Definitions

    struct ContextTag: Identifiable {
        let key: String
        let label: String
        let icon: String

        var id: String { key }
    }

    static let availableTags: [ContextTag] = [
        ContextTag(key: "forge", label: "Building a company", icon: "building.2"),
        ContextTag(key: "cap", label: "Raising capital", icon: "chart.line.uptrend.xyaxis"),
        ContextTag(key: "reloc", label: "Considering relocation", icon: "globe.asia.australia"),
        ContextTag(key: "job", label: "Career transition", icon: "arrow.triangle.branch"),
        ContextTag(key: "rel", label: "New relationship", icon: "heart"),
        ContextTag(key: "body", label: "Health rebuild", icon: "heart.circle"),
        ContextTag(key: "home", label: "Buying property", icon: "house"),
        ContextTag(key: "voice", label: "Writing / public output", icon: "pencil.and.outline"),
        ContextTag(key: "law", label: "Legal / litigation", icon: "building.columns"),
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    (
                        Text("What is the chart ")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.cosmicTextPrimary)
                        +
                        Text("actually")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(Color.cosmicGold)
                        +
                        Text(" running on?")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )
                    .lineSpacing(2)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)

                    Text("Without context, predictions are vapor. Pick what's loaded — we'll prior the Bayesian engine.")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.lg)

                // MARK: - Tag Chips
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("CONTEXT TAGS")
                        .font(.cosmicMicro)
                        .tracking(CosmicTypography.Tracking.uppercase)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .padding(.horizontal, Cosmic.Spacing.screen)

                    ContextFlowLayout(spacing: 8) {
                        ForEach(Array(Self.availableTags.enumerated()), id: \.element.id) { index, tag in
                            contextChip(tag: tag, index: index)
                        }
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }
                .padding(.top, Cosmic.Spacing.lg)

                // MARK: - Free-Text Field
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("OPEN FIELD · NLP PARSE")
                        .font(.cosmicMicro)
                        .tracking(CosmicTypography.Tracking.uppercase)
                        .foregroundStyle(Color.cosmicTextTertiary)

                    ZStack(alignment: .topLeading) {
                        if freeTextContext.isEmpty && !isTextFieldFocused {
                            Text(placeholderExample)
                                .font(.system(size: 13.5, design: .serif))
                                .italic()
                                .foregroundStyle(Color.cosmicTextTertiary.opacity(0.6))
                                .lineSpacing(4)
                                .padding(.horizontal, Cosmic.Spacing.md)
                                .padding(.vertical, Cosmic.Spacing.sm)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $freeTextContext)
                            .font(.system(size: 13.5, design: .serif))
                            .italic()
                            .foregroundStyle(
                                freeTextContext.isEmpty
                                    ? Color.cosmicTextTertiary.opacity(0.4)
                                    : Color.cosmicTextSecondary
                            )
                            .lineSpacing(4)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, Cosmic.Spacing.sm)
                            .padding(.vertical, Cosmic.Spacing.xxs)
                            .frame(minHeight: 100)
                            .accessibilityLabel("Free-text context")
                            .accessibilityHint("Describe your current situation for better predictions")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card - 2, style: .continuous)
                            .fill(Color.cosmicSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                            .stroke(
                                isTextFieldFocused
                                    ? Color.cosmicGold.opacity(0.4)
                                    : Color.cosmicTextTertiary.opacity(0.15),
                                lineWidth: Cosmic.Border.hairline
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                    .animation(.cosmicQuick, value: isTextFieldFocused)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.lg)

                // MARK: - Extracted Summary
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    HStack(spacing: 0) {
                        Text("extracted → ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextTertiary)

                        Text(extractedSummary)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicGold)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.sm)

                Spacer(minLength: Cosmic.Spacing.xl)
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("onboarding.contextPriors")
        .onAppear {
            if !reduceMotion {
                withAnimation(.cosmicReveal.delay(0.2)) { animateTags = true }
            } else {
                animateTags = true
            }
        }
    }

    // MARK: - Chip View

    @ViewBuilder
    private func contextChip(tag: ContextTag, index: Int) -> some View {
        let isActive = selectedTags.contains(tag.key)

        Button {
            withAnimation(.cosmicSnappy) {
                if isActive {
                    selectedTags.removeAll { $0 == tag.key }
                } else {
                    selectedTags.append(tag.key)
                }
            }
            CosmicHaptics.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(tag.label)
                    .font(.cosmicCaption)
            }
            .foregroundStyle(isActive ? Color.cosmicVoid : Color.cosmicTextSecondary)
            .padding(.horizontal, Cosmic.Spacing.sm)
            .padding(.vertical, Cosmic.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                    .fill(isActive ? Color.cosmicGold : Color.cosmicSurfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                    .stroke(
                        isActive
                            ? Color.cosmicGold
                            : Color.cosmicTextTertiary.opacity(0.15),
                        lineWidth: Cosmic.Border.hairline
                    )
            )
            .opacity(animateTags ? 1 : 0)
            .scaleEffect(animateTags ? 1 : 0.8)
            .animation(.cosmicSpring.delay(Double(index) * 0.04), value: animateTags)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tag.label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .accessibilityHint(isActive ? "Selected" : "Tap to select")
        .accessibilityValue(isActive ? "active" : "inactive")
    }

    // MARK: - Placeholder

    private var placeholderExample: String {
        """
        "Running Forge (infra co) + advising Visusta. SpaceXAI email \
        last week. Looking at Dubai base by Q3, Singapore entity by Oct."
        """
    }

    // MARK: - NLP Extraction Heuristic

    private var extractedSummary: String {
        var parts: [String] = []

        // Count ventures: heuristics on company-ish keywords and proper nouns
        let text = freeTextContext.lowercased()
        let ventureCount = countVentures(in: text)

        // Count geos: city/country mentions
        let geoNames = ["dubai", "singapore", "london", "nyc", "new york",
                        "sf", "san francisco", "bangalore", "mumbai", "delhi",
                        "berlin", "paris", "tokyo", "toronto", "sydney"]
        let geoCount = geoNames.filter { text.contains($0) }.count

        // Count inbounds: email, DM, intro patterns
        let inboundPatterns = ["email", "dm", "intro", "reach out", "inbound",
                               "contacted", "referred", "introduction"]
        let inboundCount = inboundPatterns.filter { text.contains($0) }.count

        if ventureCount > 0 {
            parts.append("\(ventureCount) venture\(ventureCount > 1 ? "s" : "")")
        }
        if geoCount > 0 {
            parts.append("\(geoCount) geo\(geoCount > 1 ? "s" : "")")
        } else if selectedTags.contains("reloc") {
            parts.append("1 geo")
        }
        if inboundCount > 0 {
            parts.append("\(inboundCount) inbound\(inboundCount > 1 ? "s" : "")")
        }

        if parts.isEmpty {
            let tagCount = selectedTags.count
            if tagCount > 0 {
                return "\(tagCount) signal\(tagCount > 1 ? "s" : "") loaded"
            }
            return "awaiting context"
        }

        return parts.joined(separator: " · ")
    }

    private func countVentures(in text: String) -> Int {
        // Heuristic: count parenthetical patterns like "Forge (infra co)"
        // or "co)" patterns that suggest named entities
        let coPattern = text.components(separatedBy: " co)").count - 1
        let ventureKeywords = ["forge", "visusta", "spacexai", "running", "advising",
                               "building", "founding", "startup", "company"]
        let keywordHits = ventureKeywords.filter { text.contains($0) }.count

        // Co-patterns are strong signals; supplement with keyword clusters
        let coBased = max(coPattern, 0)
        let keywordBased = (keywordHits / 3) // rough cluster heuristic

        return max(coBased, keywordBased, selectedTags.contains("forge") ? 2 : 0)
    }
}

// MARK: - FlowLayout

/// A basic flow layout for tag chips. Wraps content to the next row when
/// horizontal space is exhausted.
private struct ContextFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        guard !rows.isEmpty else { return .zero }

        var maxRowWidth: CGFloat = 0
        for row in rows {
            var rowWidth: CGFloat = 0
            for item in row {
                rowWidth += item.sizeThatFits(.unspecified).width
            }
            rowWidth += CGFloat(max(0, row.count - 1)) * spacing
            maxRowWidth = max(maxRowWidth, rowWidth)
        }

        var totalHeight: CGFloat = 0
        for row in rows {
            var maxItemHeight: CGFloat = 0
            for item in row {
                maxItemHeight = max(maxItemHeight, item.sizeThatFits(.unspecified).height)
            }
            totalHeight += maxItemHeight
        }
        totalHeight += CGFloat(max(0, rows.count - 1)) * spacing

        return CGSize(width: max(maxRowWidth, proposal.width ?? 0), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX

            for item in row {
                item.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += item.sizeThatFits(.unspecified).width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = size.width + (currentRow.isEmpty ? 0 : spacing)

            if !currentRow.isEmpty, currentWidth + itemWidth > maxWidth {
                rows.append(currentRow)
                currentRow = [subview]
                currentWidth = size.width
            } else {
                currentRow.append(subview)
                currentWidth += itemWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Context Priors Step — With Selections") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        ContextPriorsStepView(
            selectedTags: .constant(["forge", "cap", "reloc", "voice"]),
            freeTextContext: .constant(
                "Running Forge (infra co) + advising Visusta. SpaceXAI email last week. Looking at Dubai base by Q3, Singapore entity by Oct."
            )
        )
    }
}

#Preview("Context Priors Step — Empty") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        ContextPriorsStepView(
            selectedTags: .constant([]),
            freeTextContext: .constant("")
        )
    }
}

#Preview("Context Priors Step — Tags Only") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        ContextPriorsStepView(
            selectedTags: .constant(["job", "rel", "body"]),
            freeTextContext: .constant("")
        )
    }
}
#endif
