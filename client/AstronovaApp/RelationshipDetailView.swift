import SwiftUI

// MARK: - Relationship Detail View
// Main container for compatibility - 3 pillars: Overview, Journey, Proof
// Uses segmented control or sticky subnav chips.

struct RelationshipDetailView: View {
    let profile: RelationshipProfile

    @State private var snapshot: CompatibilitySnapshot?
    @State private var selectedTab: DetailTab = .overview
    @State private var selectedAspect: SynastryAspect?
    @State private var selectedPlanet: (person: SynastryCompassView.Person, planet: String)?
    @State private var focusDomain: Domain?
    @State private var selectedDate = Date()
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var showPulseSheet = false
    @State private var showInsightSheet = false
    @State private var showAspectSheet = false
    @State private var showShareSheet = false
    @State private var scrollOffset: CGFloat = 0

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case journey = "Journey"
        case proof = "Proof"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.cosmicBackground.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if let data = snapshot {
                mainContent(data: data)
            }
        }
        .background(Color.cosmicBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(profile.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if snapshot != nil {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.cosmicGold)
                    }
                }
            }
        }
        .task {
            await loadSnapshot()
        }
        .onChange(of: selectedDate) { _, newDate in
            Task { await loadSnapshot(for: newDate) }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.cosmicGold)

            Text("Calculating compatibility...")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)

            Text("Analyzing synastry aspects and relationship energy")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Cosmic.Spacing.xl)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.cosmicWarning)

            Text("Couldn't load compatibility")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(error.localizedDescription)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Cosmic.Spacing.xl)

            Button {
                Task { await loadSnapshot() }
            } label: {
                Text("Try Again")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.lg)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
            }
        }
    }

    // MARK: - Load Snapshot

    private func loadSnapshot(for date: Date? = nil) async {
        isLoading = snapshot == nil
        loadError = nil

        do {
            snapshot = try await APIServices.shared.getCompatibilitySnapshot(
                relationshipId: profile.id,
                date: date
            )
        } catch {
            loadError = error
            #if DEBUG
            print("[RelationshipDetailView] Failed to load snapshot: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(data: CompatibilitySnapshot) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header (collapsible)
                    headerSection(data: data)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                            }
                        )

                    // Tab content
                    tabContent(data: data)
                        .padding(.top, 16)
                }
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }

            // Compact header (shows when scrolled)
            if scrollOffset < -100 {
                compactHeader(data: data)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPulseSheet) {
            PulseExplanationSheet(pulse: data.now.pulse)
        }
        .sheet(isPresented: $showInsightSheet) {
            SharedInsightDetailSheet(
                insight: data.now.sharedInsight,
                linkedAspects: data.synastry.topAspects.filter {
                    data.now.sharedInsight.linkedAspectIds.contains($0.id)
                }
            )
        }
        .sheet(item: $selectedAspect) { aspect in
            AspectDetailSheet(aspect: aspect, synastry: data.synastry)
        }
        .sheet(isPresented: $showShareSheet) {
            RelationshipShareSheet(share: data.share, pairNames: "\(data.pair.nameA) & \(data.pair.nameB)")
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(data: CompatibilitySnapshot) -> some View {
        VStack(spacing: 16) {
            // Pair avatars with connection line
            pairAvatars(data: data)

            // Shared signature
            Text(data.pair.sharedSignature)
                .font(.subheadline)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Relationship Pulse
            RelationshipPulseView(pulse: data.now.pulse, isCompact: false) {
                showPulseSheet = true
            }
            .padding(.horizontal)

            // Tab picker
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func pairAvatars(data: CompatibilitySnapshot) -> some View {
        HStack(spacing: 0) {
            // Person A avatar
            avatarView(name: data.pair.nameA, color: Color.cosmicGold)

            // Connection line with overall score
            ZStack {
                // Line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cosmicGold, Color(red: 0.9, green: 0.6, blue: 0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(width: 60)

                // Score badge
                Text("\(data.synastry.overallScore)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.cosmicSurface)
                            .overlay(
                                Capsule()
                                    .stroke(Color.cosmicNebula, lineWidth: 1)
                            )
                    )
            }

            // Person B avatar
            avatarView(name: data.pair.nameB, color: Color(red: 0.9, green: 0.6, blue: 0.7))
        }
    }

    private func avatarView(name: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.6), color.opacity(0.2)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.cosmicTextPrimary)
                )

            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }

    // MARK: - Compact Header

    @ViewBuilder
    private func compactHeader(data: CompatibilitySnapshot) -> some View {
        HStack(spacing: 12) {
            // Mini avatars
            HStack(spacing: -8) {
                Circle()
                    .fill(Color.cosmicGold.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(data.pair.nameA.prefix(1)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )

                Circle()
                    .fill(Color(red: 0.9, green: 0.6, blue: 0.7).opacity(0.5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(data.pair.nameB.prefix(1)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )
            }

            Text("\(data.pair.nameA) & \(data.pair.nameB)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            MiniPulseView(pulse: data.now.pulse)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(data: CompatibilitySnapshot) -> some View {
        switch selectedTab {
        case .overview:
            overviewTab(data: data)
        case .journey:
            journeyTab(data: data)
        case .proof:
            proofTab(data: data)
        }
    }

    // MARK: - Overview Tab

    @ViewBuilder
    private func overviewTab(data: CompatibilitySnapshot) -> some View {
        VStack(spacing: 20) {
            // Domain filter chips
            DomainFilterChips(selectedDomain: $focusDomain)

            // Synastry Compass
            SynastryCompassView(
                natalA: data.natalA,
                natalB: data.natalB,
                synastry: data.synastry,
                selectedAspect: $selectedAspect,
                selectedPlanet: $selectedPlanet,
                focusDomain: $focusDomain,
                onAspectTapped: { aspect in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAspectSheet = true
                    }
                }
            )
            .padding(.horizontal)

            // Meaning Stack
            CompatibilityMeaningStack(
                now: data.now,
                next: data.next,
                isCompact: false,
                onNowTapped: { showInsightSheet = true },
                onNextTapped: { selectedTab = .journey },
                onActionTapped: { showInsightSheet = true }
            )
            .padding(.horizontal)

            // Core Connections (top aspects)
            coreConnectionsSection(data: data)
        }
    }

    @ViewBuilder
    private func coreConnectionsSection(data: CompatibilitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Core Connections")
                .font(.headline)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding(.horizontal)

            ForEach(data.synastry.topAspects.prefix(5)) { aspect in
                CoreConnectionCard(
                    aspect: aspect,
                    isSelected: selectedAspect?.id == aspect.id,
                    onTap: {
                        selectedAspect = aspect
                        showAspectSheet = true
                        CosmicHaptics.light()
                    }
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Journey Tab

    @ViewBuilder
    private func journeyTab(data: CompatibilitySnapshot) -> some View {
        VStack(spacing: 20) {
            CompatibilityJourneyView(
                journey: data.journey,
                selectedDate: $selectedDate,
                onDateSelected: { date in
                    // Fetch snapshot for new date
                }
            )
            .padding(.horizontal)

            // Next shift detail
            NextShiftCard(next: data.next)
                .padding(.horizontal)
        }
    }

    // MARK: - Proof Tab

    @ViewBuilder
    private func proofTab(data: CompatibilitySnapshot) -> some View {
        VStack(spacing: 20) {
            // Domain breakdown
            DomainBreakdownView(domains: data.synastry.domainBreakdown)
                .padding(.horizontal)

            // Synastry aspects table
            SynastryAspectsTable(aspects: data.synastry.topAspects)
                .padding(.horizontal)

            // Charts comparison (placeholder)
            ChartsComparisonView(natalA: data.natalA, natalB: data.natalB, pair: data.pair)
                .padding(.horizontal)
        }
    }
}

// MARK: - Core Connection Card

struct CoreConnectionCard: View {
    let aspect: SynastryAspect
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Aspect glyphs
                HStack(spacing: 4) {
                    Text(aspect.planetAGlyph)
                        .foregroundStyle(Color.cosmicGold)
                    Text(aspect.aspectGlyph)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(aspect.planetBGlyph)
                        .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.7))
                }
                .font(.title3.weight(.medium))
                .frame(width: 70)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(aspect.interpretation.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if aspect.isActivatedNow {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }

                    Text(aspect.interpretation.oneLiner)
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Strength indicator
                StrengthBar(strength: aspect.strength, isHarmonious: aspect.isHarmonious)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cosmicSurfaceSecondary : Color.cosmicSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.cosmicGold.opacity(0.5) : Color.cosmicNebula,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct StrengthBar: View {
    let strength: Double
    let isHarmonious: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.cosmicNebula)
                    .frame(width: 40, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(isHarmonious ? Color.cosmicGold : Color(red: 0.95, green: 0.5, blue: 0.5))
                    .frame(width: CGFloat(strength) * 40, height: 4)
            }

            Text("\(Int(strength * 100))%")
                .font(.system(size: 8).monospacedDigit())
                .foregroundStyle(Color.cosmicTextTertiary)
        }
    }
}

// MARK: - Next Shift Card

struct NextShiftCard: View {
    let next: NextShift

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color.cosmicTeal)
                Text("Next Shift")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Text("in \(next.daysUntil) days")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Text(next.whatChanges)
                .font(.body)
                .foregroundStyle(Color.cosmicTextSecondary)

            Divider()
                .background(Color.cosmicNebula)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.cosmicGold.opacity(0.7))
                Text(next.planForIt)
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cosmicTeal.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Domain Breakdown View

struct DomainBreakdownView: View {
    let domains: [DomainScore]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Domain Breakdown")
                .font(.headline)
                .foregroundStyle(Color.cosmicTextPrimary)

            ForEach(domains) { domain in
                DomainRow(domain: domain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cosmicSurface)
        )
    }
}

struct DomainRow: View {
    let domain: DomainScore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: domain.domain.icon)
                .font(.body)
                .foregroundStyle(Color.cosmicGold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(domain.domain.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("\(domain.signA) ↔ \(domain.signB)")
                    .font(.caption2)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()

            Text("\(domain.score)%")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(scoreColor(domain.score))
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color.cosmicGold }
        if score >= 60 { return Color.cosmicTeal }
        if score >= 40 { return Color.cosmicTextSecondary }
        return Color(red: 0.95, green: 0.5, blue: 0.5)
    }
}

// MARK: - Synastry Aspects Table

struct SynastryAspectsTable: View {
    let aspects: [SynastryAspect]
    @State private var sortBy: SortOption = .strength

    enum SortOption: String, CaseIterable {
        case strength = "Strength"
        case type = "Type"
        case activated = "Active"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Aspects")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Spacer()

                Picker("Sort", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(Color.cosmicGold)
            }

            ForEach(sortedAspects) { aspect in
                AspectTableRow(aspect: aspect)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cosmicSurface)
        )
    }

    private var sortedAspects: [SynastryAspect] {
        switch sortBy {
        case .strength:
            return aspects.sorted { $0.strength > $1.strength }
        case .type:
            return aspects.sorted { $0.aspectType.rawValue < $1.aspectType.rawValue }
        case .activated:
            return aspects.sorted { $0.isActivatedNow && !$1.isActivatedNow }
        }
    }
}

struct AspectTableRow: View {
    let aspect: SynastryAspect

    var body: some View {
        HStack(spacing: 8) {
            Text("\(aspect.planetA) \(aspect.aspectGlyph) \(aspect.planetB)")
                .font(.caption.monospaced())
                .foregroundStyle(Color.cosmicTextSecondary)

            Spacer()

            Text(String(format: "%.1f°", aspect.orb))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color.cosmicTextTertiary)

            if aspect.isActivatedNow {
                Circle()
                    .fill(Color.cosmicGold)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Charts Comparison View

struct ChartsComparisonView: View {
    let natalA: NatalPlacements
    let natalB: NatalPlacements
    let pair: RelationshipPair

    @State private var viewMode: ViewMode = .table

    enum ViewMode: String, CaseIterable {
        case table = "Table"
        case circle = "Circle"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Charts Comparison")
                    .font(.headline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Spacer()

                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            if viewMode == .table {
                chartTable
            } else {
                Text("Circle view coming soon")
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cosmicSurface)
        )
    }

    private var chartTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Planet")
                    .frame(width: 70, alignment: .leading)
                Text(pair.nameA)
                    .frame(maxWidth: .infinity)
                Text(pair.nameB)
                    .frame(maxWidth: .infinity)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.cosmicTextTertiary)
            .padding(.bottom, 8)

            Divider().background(Color.cosmicNebula)

            // Rows
            ForEach(Array(zip(natalA.allPlacements, natalB.allPlacements)), id: \.0.name) { (placementA, placementB) in
                HStack {
                    Text(placementA.name)
                        .frame(width: 70, alignment: .leading)
                    Text("\(placementA.placement.signGlyph) \(placementA.placement.formattedDegree)")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.cosmicGold)
                    Text("\(placementB.placement.signGlyph) \(placementB.placement.formattedDegree)")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.7))
                }
                .font(.caption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.vertical, 6)

                Divider().background(Color.cosmicNebula.opacity(0.5))
            }
        }
    }
}

// MARK: - Aspect Detail Sheet

struct AspectDetailSheet: View {
    let aspect: SynastryAspect
    let synastry: SynastryData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Text(aspect.planetAGlyph)
                                .font(.largeTitle)
                                .foregroundStyle(Color.cosmicGold)
                            Text(aspect.aspectGlyph)
                                .font(.title)
                                .foregroundStyle(Color.cosmicTextTertiary)
                            Text(aspect.planetBGlyph)
                                .font(.largeTitle)
                                .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.7))
                        }

                        Text(aspect.interpretation.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if aspect.isActivatedNow {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Currently Active")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.cosmicGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cosmicGold.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider().background(Color.cosmicNebula)

                    // One-liner
                    Text(aspect.interpretation.oneLiner)
                        .font(.body)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    // Deep dive
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deep Dive")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(aspect.interpretation.deepDive)
                            .font(.body)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Divider().background(Color.cosmicNebula)

                    // Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aligning With This Frequency")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        ActionRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            label: "Do",
                            text: aspect.interpretation.suggestedAction
                        )

                        ActionRow(
                            icon: "xmark.circle.fill",
                            iconColor: .red.opacity(0.8),
                            label: "Avoid",
                            text: aspect.interpretation.avoidAction
                        )
                    }

                    // Technical details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cosmicTextTertiary)

                        HStack {
                            TechDetail(label: "Aspect", value: aspect.aspectType.rawValue.capitalized)
                            TechDetail(label: "Orb", value: String(format: "%.1f°", aspect.orb))
                            TechDetail(label: "Strength", value: "\(Int(aspect.strength * 100))%")
                        }
                    }
                    .padding()
                    .background(Color.cosmicSurface)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("Aspect Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
    }
}

struct TechDetail: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.cosmicTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Relationship Share Sheet

struct RelationshipShareSheet: View {
    let share: ShareModel
    let pairNames: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview card
                shareCardPreview
                    .padding()

                // Share options
                VStack(spacing: 12) {
                    ShareButton(icon: "message.fill", label: "Messages", color: .green) {
                        // Share via messages
                    }
                    ShareButton(icon: "square.and.arrow.up", label: "More", color: .blue) {
                        // System share sheet
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("Share Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
        }
    }

    private var shareCardPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(share.cardTitle)
                .font(.headline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(share.cardSentence)
                .font(.body)
                .foregroundStyle(Color.cosmicTextSecondary)

            Divider().background(Color.cosmicNebula)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(share.cardAction, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label(share.cardAvoid, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .font(.caption)

                Spacer()
            }

            Text("Based on \(pairNames)'s charts")
                .font(.caption2)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cosmicGold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ShareButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding()
            .background(Color.cosmicSurface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scroll Offset Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RelationshipDetailView(profile: RelationshipProfile.mockList[0])
    }
}
