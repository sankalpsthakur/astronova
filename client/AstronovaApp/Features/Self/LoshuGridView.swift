import SwiftUI

// MARK: - Loshu Grid Data Models

/// Complete Loshu Grid analysis for a birth date.
/// The 3x3 Loshu magic square is personalized by marking which positions
/// appear in the user's date-of-birth digits.
struct LoshuData: Codable {
    /// 3x3 grid in standard Loshu layout.
    /// Value is the Loshu position number if present, 0 if missing.
    let grid: [[Int]]

    /// How many times each digit (1-9) appears in the birth date.
    let counts: [String: Int]

    /// Digits 1-9 that do NOT appear in the birth date.
    let missing: [Int]

    /// Digits 1-9 that DO appear in the birth date.
    let present: [Int]

    /// Eigenvalues of the personalized 3x3 Loshu matrix (descending).
    let eigenvalues: [Double]

    /// The 8 planes (3 rows, 3 columns, 2 diagonals) with completion status.
    let completedPlanes: [PlaneInfo]

    /// Driver number (day-of-birth reduced to single digit, master numbers preserved).
    let driverNumber: Int

    /// Conductor number (sum of all DOB digits reduced to single digit).
    let conductorNumber: Int
}

/// A single plane (row, column, or diagonal) within the Loshu grid.
struct PlaneInfo: Identifiable, Codable {
    let id = UUID()
    /// Human-readable name for this plane.
    let name: String
    /// The three Loshu numbers that make up this plane.
    let numbers: [Int]
    /// Whether all three numbers appear in the birth date.
    let isComplete: Bool
    /// Plain-language description of what this plane governs in a person's life.
    let description: String

    enum CodingKeys: String, CodingKey {
        case name
        case numbers
        case isComplete
        case description
    }
}

// MARK: - Loshu Grid View

/// Interactive 3x3 Loshu Grid numerology analysis with eigenvalue mathematics.
/// Sections: the grid itself, eigenvalue decomposition, completed planes,
/// missing-number analysis, and driver/conductor summary.
struct LoshuGridView: View {
    let data: LoshuData
    private let embedded: Bool

    // MARK: - Animation State

    @State private var appears = false
    @State private var selectedPlane: PlaneInfo? = nil
    @State private var highlightedNumber: Int? = nil

    init(data: LoshuData, embedded: Bool = false) {
        self.data = data
        self.embedded = embedded
    }

    // MARK: - Body

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                ScrollView {
                    content
                }
            }
        }
        .background(Color.cosmicBackground)
        .onAppear {
            withAnimation(.cosmicReveal.delay(0.1)) { appears = true }
        }
        .accessibilityIdentifier("loshuGridView")
    }

    private var content: some View {
        VStack(spacing: Cosmic.Spacing.xl) {

            // Section 1 — The Grid (centerpiece)
            loshuGridSection

            // Section 2 — Eigenvalue Analysis
            eigenvalueCard

            // Section 3 — Completed Planes
            planesSection

            // Section 4 — Missing Numbers Analysis
            missingNumbersSection

            // Section 5 — Driver & Conductor
            driverConductorSection
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.vertical, Cosmic.Spacing.xl)
    }

    // MARK: - Section 1: Loshu Grid

    private var loshuGridSection: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            // Section label
            CosmicText(text: "Loshu Grid", style: .title2)

            Text("Your birth-date digits placed in the sacred 3x3 square")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)

            // The 3x3 grid
            gridView
                .padding(.top, Cosmic.Spacing.sm)

            // Legend
            legendRow
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 16)
    }

    private var gridView: some View {
        let cellSize: CGFloat = 70

        return VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let value = data.grid[row][col]
                        gridCell(
                            loshuNumber: loshuLayout[row][col],
                            value: value,
                            size: cellSize
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(cellAccessibilityLabel(
                            row: row, col: col,
                            loshuNumber: loshuLayout[row][col],
                            value: value
                        ))
                        .accessibilityAddTraits(value > 0 ? .isButton : .isStaticText)
                    }
                }
                // Horizontal dividers between rows
                if row < 2 {
                    Rectangle()
                        .fill(Color.cosmicTextTertiary.opacity(0.15))
                        .frame(height: Cosmic.Border.thin)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: Cosmic.Border.thin)
        )
        .accessibilityIdentifier("loshuGridView")
    }

    /// The standard Loshu magic square layout.
    private let loshuLayout: [[Int]] = [
        [4, 9, 2],
        [3, 5, 7],
        [8, 1, 6]
    ]

    @ViewBuilder
    private func gridCell(loshuNumber: Int, value: Int, size: CGFloat) -> some View {
        let count = data.counts[String(loshuNumber)] ?? 0
        let isPresent = value > 0
        let isTriple = count >= 3
        let isDouble = count == 2

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(isPresent
                    ? Color.cosmicGold.opacity(0.15)
                    : Color.cosmicSurface.opacity(0.5)
                )

            // Vertical dividers (inset within cell)
            // Handled by HStack spacing = 0 plus separator lines

            VStack(spacing: Cosmic.Spacing.hair) {
                if isPresent {
                    // Present: large number
                    Text("\(loshuNumber)")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .monospacedDigit()

                    // Repetition dots
                    if count > 1 {
                        HStack(spacing: 3) {
                            ForEach(0..<min(count, 5), id: \.self) { _ in
                                Circle()
                                    .fill(Color.cosmicGold)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                } else {
                    // Missing: faint number
                    Text("\(loshuNumber)")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextTertiary.opacity(0.3))
                        .monospacedDigit()
                }
            }
        }
        .frame(width: size, height: size)
        // Border highlights
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .strokeBorder(
                    isTriple ? Color.cosmicGold : (isDouble ? Color.cosmicAmethyst : Color.clear),
                    lineWidth: isTriple ? Cosmic.Border.medium : (isDouble ? Cosmic.Border.thin : 0)
                )
        )
        .animation(.cosmicSmooth, value: highlightedNumber)
    }

    private func cellAccessibilityLabel(row: Int, col: Int, loshuNumber: Int, value: Int) -> String {
        let count = data.counts[String(loshuNumber)] ?? 0
        let status = value > 0
            ? (count >= 3 ? "triple, \(count) times" : (count == 2 ? "double" : "present, once"))
            : "missing"
        return "Row \(row + 1), Column \(col + 1): Number \(loshuNumber), \(status)"
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Cosmic.Spacing.md) {
            legendDot(color: .cosmicGold, label: "Triple (3+)")
            legendDot(color: .cosmicAmethyst, label: "Double (2)")
            legendDot(color: .cosmicTextTertiary.opacity(0.3), label: "Missing")
        }
        .font(.cosmicCaption)
        .foregroundStyle(Color.cosmicTextTertiary)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Cosmic.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }

    // MARK: - Section 2: Eigenvalue Analysis

    private var eigenvalueCard: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "function")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicGold)
                CosmicText(text: "Eigenvalue Decomposition", style: .headline)
            }

            Divider()
                .overlay(Color.cosmicTextTertiary.opacity(0.15))

            // Eigenvalues listing
            eigenvalueRow(
                symbol: "\u{03BB}\u{2081}",
                value: data.eigenvalues[0],
                label: eigenvalueLabel(for: data.eigenvalues[0]),
                color: .cosmicGold
            )

            eigenvalueRow(
                symbol: "\u{03BB}\u{2082}",
                value: data.eigenvalues[1],
                label: eigenvalueLabel(for: data.eigenvalues[1]),
                color: .cosmicAmethyst
            )

            eigenvalueRow(
                symbol: "\u{03BB}\u{2083}",
                value: data.eigenvalues[2],
                label: zeroEigenvalueExplanation,
                color: .cosmicError
            )
        }
        .cosmicCard(background: Color.cosmicSurface, radius: Cosmic.Radius.card)
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 20)
    }

    private func eigenvalueRow(symbol: String, value: Double, label: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Cosmic.Spacing.sm) {
            // Symbol
            Text(symbol)
                .font(.cosmicMonoLarge)
                .foregroundStyle(color)
                .frame(width: 28, alignment: .leading)

            // Numeric value
            Text(String(format: "%.1f", value))
                .font(.cosmicMonoLarge)
                .foregroundStyle(color)

            Text("=")
                .font(.cosmicMono)
                .foregroundStyle(Color.cosmicTextTertiary)

            // Interpretation
            Text(label)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, Cosmic.Spacing.xxs)
    }

    private func eigenvalueLabel(for value: Double) -> String {
        if value >= 3.0 {
            return "Dominant structure — multiple complete planes provide strong life foundation"
        } else if value >= 1.0 {
            return "Secondary axis — partial coherence through a completed row or column"
        } else {
            return "Neutral — neither reinforces nor destabilizes"
        }
    }

    private var zeroEigenvalueExplanation: String {
        let missingPlaneNames = data.completedPlanes
            .filter { !$0.isComplete }
            .prefix(3)
            .map { $0.name }
            .joined(separator: ", ")
        return "Zero eigenvalue — structural instability in \(missingPlaneNames)"
    }

    // MARK: - Section 3: Completed Planes

    private var planesSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            CosmicText(text: "The Eight Planes", style: .headline)

            Text("Each row, column, and diagonal governs a life dimension. Complete planes indicate areas of natural strength.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVStack(spacing: Cosmic.Spacing.xs) {
                ForEach(data.completedPlanes) { plane in
                    planeRow(plane)
                }
            }
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 24)
    }

    private func planeRow(_ plane: PlaneInfo) -> some View {
        Button {
            withAnimation(.cosmicSpring) {
                selectedPlane = (selectedPlane?.id == plane.id) ? nil : plane
            }
            CosmicHaptics.selection()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    // Completion indicator
                    ZStack {
                        Circle()
                            .fill(plane.isComplete
                                ? Color.cosmicGold.opacity(0.2)
                                : Color.cosmicSurfaceSecondary
                            )
                            .frame(width: 28, height: 28)
                        if plane.isComplete {
                            Image(systemName: "checkmark")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicGold)
                        } else {
                            Image(systemName: "xmark")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextTertiary)
                        }
                    }

                    // Plane name
                    Text(plane.name)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(plane.isComplete
                            ? Color.cosmicTextPrimary
                            : Color.cosmicTextSecondary
                        )

                    Spacer()

                    // Number chips
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        ForEach(plane.numbers, id: \.self) { num in
                            Text("\(num)")
                                .font(.cosmicCaption)
                                .foregroundStyle(data.present.contains(num)
                                    ? Color.cosmicGold
                                    : Color.cosmicTextTertiary
                                )
                                .padding(.horizontal, Cosmic.Spacing.xxs)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                                        .fill(data.present.contains(num)
                                            ? Color.cosmicGold.opacity(0.15)
                                            : Color.clear
                                        )
                                )
                        }
                    }
                }
                .padding(.vertical, Cosmic.Spacing.sm)

                // Expanded tooltip
                if selectedPlane?.id == plane.id {
                    Text(plane.description)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .padding(.horizontal, Cosmic.Spacing.sm)
                        .padding(.bottom, Cosmic.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.cosmicSlideUp)
                }

                Divider()
                    .overlay(Color.cosmicTextTertiary.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(plane.isComplete ? "Complete plane. Tap for description." : "Incomplete plane. Tap for description.")
    }

    // MARK: - Section 4: Missing Numbers Analysis

    private var missingNumbersSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            CosmicText(text: "Missing Numbers", style: .headline)

            Text("These energies are absent from your birth date. Awareness is the first step toward compensation.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if data.missing.isEmpty {
                // Rare: all numbers present
                HStack(spacing: Cosmic.Spacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.cosmicGold)
                    Text("All numbers 1-9 present — a fully populated Loshu grid.")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(Cosmic.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicGold.opacity(0.08))
                )
            } else {
                ForEach(data.missing, id: \.self) { number in
                    missingNumberRow(number)
                }
            }
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 28)
    }

    private func missingNumberRow(_ number: Int) -> some View {
        let ruling = numberRulership[number] ?? (planet: "Unknown", domain: "Unknown")
        let recommendation = guardrailRecommendation(for: number)

        return VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            HStack(alignment: .center, spacing: Cosmic.Spacing.sm) {
                // Number badge
                Text("\(number)")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.cosmicSurfaceSecondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ruling.planet) — \(ruling.domain)")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                Spacer()
            }

            // Guardrail recommendation
            HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicAmethyst)
                    .padding(.top, 1)
                Text(recommendation)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 36 + Cosmic.Spacing.sm)

            Divider()
                .overlay(Color.cosmicTextTertiary.opacity(0.08))
                .padding(.top, Cosmic.Spacing.xxs)
        }
    }

    /// Planet/sign rulership for each Loshu number.
    private let numberRulership: [Int: (planet: String, domain: String)] = [
        1: ("Sun", "Individuality"),
        2: ("Moon", "Sensitivity"),
        3: ("Jupiter", "Expression"),
        4: ("Rahu", "Structure"),
        5: ("Mercury", "Balance"),
        6: ("Venus", "Harmony"),
        7: ("Ketu", "Depth"),
        8: ("Saturn", "Material grounding"),
        9: ("Mars", "Drive")
    ]

    private func guardrailRecommendation(for number: Int) -> String {
        switch number {
        case 1: return "Practice taking initiative daily. Lead small decisions. Wear gold or copper to strengthen solar energy."
        case 2: return "Cultivate emotional awareness through journaling. Spend time near water. Practice active listening."
        case 3: return "Express yourself through writing or speaking. Seek mentors. Wear yellow or engage in teaching."
        case 4: return "Build structure through routine. Use checklists. Ground yourself with earthy activities like gardening."
        case 5: return "Create balance through scheduled flexibility. Practice mental agility with puzzles or languages. Stay curious."
        case 6: return "Nurture relationships intentionally. Create beauty in your space. Practice gratitude for the people around you."
        case 7: return "Develop depth through meditation or research. Embrace solitude without isolation. Trust your intuition."
        case 8: return "Ground yourself financially with disciplined saving. Build slowly. Respect limits and boundaries."
        case 9: return "Channel energy through physical activity. Take bold action on one thing each day. Avoid procrastination."
        default: return "Cultivate awareness of this missing energy and seek to embody its positive qualities."
        }
    }

    // MARK: - Section 5: Driver & Conductor

    private var driverConductorSection: some View {
        let driverRuler = numberRulership[data.driverNumber] ?? (planet: "Unknown", domain: "")
        let conductorRuler = numberRulership[data.conductorNumber] ?? (planet: "Unknown", domain: "")

        return HStack(spacing: Cosmic.Spacing.md) {
            // Driver card
            driverConductorCard(
                title: "Driver",
                number: data.driverNumber,
                ruler: driverRuler.planet,
                interpretation: "Your day-to-day personality and how others perceive you. Core motivation and natural expression."
            )

            // Conductor card
            driverConductorCard(
                title: "Conductor",
                number: data.conductorNumber,
                ruler: conductorRuler.planet,
                interpretation: "Your life path and deeper purpose. How you interact with the world across your lifetime."
            )
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 32)
    }

    private func driverConductorCard(title: String, number: Int, ruler: String, interpretation: String) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text(title.uppercased())
                .font(.cosmicMicro)
                .tracking(CosmicTypography.Tracking.uppercase)
                .foregroundStyle(Color.cosmicTextTertiary)

            HStack(alignment: .firstTextBaseline, spacing: Cosmic.Spacing.xs) {
                Text("\(number)")
                    .font(.cosmicMonoLarge)
                    .foregroundStyle(Color.cosmicGold)

                Text("(\(ruler))")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Text(interpretation)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Cosmic.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(Color.cosmicGold.opacity(0.15), lineWidth: Cosmic.Border.thin)
                )
        )
    }
}

// MARK: - Loshu Number Rulership

extension LoshuGridView {
    /// Planet (or node) associated with each Loshu number.
    static let planetForNumber: [Int: String] = [
        1: "Sun", 2: "Moon", 3: "Jupiter",
        4: "Rahu", 5: "Mercury", 6: "Venus",
        7: "Ketu", 8: "Saturn", 9: "Mars"
    ]
}

// MARK: - Preview

#if DEBUG
#Preview("DOB 24/12/1999") {
    LoshuGridView(data: LoshuGridView.sampleData)
        .preferredColorScheme(.dark)
}

#Preview("DOB 24/12/1999 — Light") {
    LoshuGridView(data: LoshuGridView.sampleData)
        .preferredColorScheme(.light)
}

extension LoshuGridView {
    /// Sample LoshuData for DOB 24/12/1999.
    ///
    /// Digits: 2, 4, 1, 2, 1, 9, 9, 9
    /// Counts: 1→2, 2→2, 4→1, 9→3. Missing: 3, 5, 6, 7, 8.
    /// Driver: day 24 → 2+4 = 6 (Venus).
    /// Conductor: 2+4+1+2+1+9+9+9 = 37 → 3+7 = 10 → 1+0 = 1 (Sun).
    static var sampleData: LoshuData {
        let counts: [String: Int] = ["1": 2, "2": 2, "3": 0, "4": 1, "5": 0, "6": 0, "7": 0, "8": 0, "9": 3]

        // Loshu layout: [[4,9,2], [3,5,7], [8,1,6]]
        // Show number only where present in birth date; 0 = missing.
        let grid: [[Int]] = [
            [4, 9, 2],   // 4 present, 9 triple-present, 2 double-present
            [0, 0, 0],   // 3, 5, 7 all missing
            [0, 1, 0]    // 8 missing, 1 double-present, 6 missing
        ]

        let allPlanes: [PlaneInfo] = [
            // Rows
            PlaneInfo(
                name: "Thought Plane (4-9-2)",
                numbers: [4, 9, 2],
                isComplete: true,
                description: "The Mental Plane. Governs intellect, creativity, and decision-making. A complete Thought Plane indicates clarity of mind and strong analytical ability."
            ),
            PlaneInfo(
                name: "Will Plane (3-5-7)",
                numbers: [3, 5, 7],
                isComplete: false,
                description: "The Will Plane. Governs determination, adaptability, and spiritual depth. When incomplete, willpower must be consciously cultivated."
            ),
            PlaneInfo(
                name: "Action Plane (8-1-6)",
                numbers: [8, 1, 6],
                isComplete: false,
                description: "The Action Plane. Governs material manifestation, leadership, and grounded results. An incomplete Action Plane suggests a need for structured follow-through."
            ),
            // Columns
            PlaneInfo(
                name: "Planning Column (4-3-8)",
                numbers: [4, 3, 8],
                isComplete: false,
                description: "Governs foresight, expansion, and discipline in execution. Links thought to material outcome through structured planning."
            ),
            PlaneInfo(
                name: "Will Column (9-5-1)",
                numbers: [9, 5, 1],
                isComplete: false,
                description: "Governs drive, communication, and leadership. The central column connects ambition with expression and personal authority."
            ),
            PlaneInfo(
                name: "Action Column (2-7-6)",
                numbers: [2, 7, 6],
                isComplete: false,
                description: "Governs sensitivity, intuition, and relationship harmony. Links emotional intelligence with depth and aesthetic balance."
            ),
            // Diagonals
            PlaneInfo(
                name: "Golden Diagonal (4-5-6)",
                numbers: [4, 5, 6],
                isComplete: false,
                description: "The prosperity axis. Connects structure (Rahu), adaptability (Mercury), and harmony (Venus). A complete Golden Diagonal signals material and relational abundance."
            ),
            PlaneInfo(
                name: "Silver Diagonal (2-5-8)",
                numbers: [2, 5, 8],
                isComplete: false,
                description: "The intuition axis. Connects sensitivity (Moon), communication (Mercury), and discipline (Saturn). A complete Silver Diagonal signals emotional wisdom and grounded intuition."
            )
        ]

        let present = counts.compactMap { (key, count) in count > 0 ? Int(key) : nil }.sorted()
        let missing = counts.compactMap { (key, count) in count == 0 ? Int(key) : nil }.sorted()

        return LoshuData(
            grid: grid,
            counts: counts,
            missing: missing,
            present: present,
            eigenvalues: [4.0, 1.0, 0.0],
            completedPlanes: allPlanes,
            driverNumber: 6,
            conductorNumber: 1
        )
    }
}
#endif
