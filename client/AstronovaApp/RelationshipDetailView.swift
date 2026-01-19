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
                .font(.cosmicDisplay)
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
                .font(.cosmicCallout)
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
                            colors: [Color.cosmicGold, Color.planetVenus],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(width: 60)

                // Intensity badge
                Text(data.synastry.overallIntensity.displayLabel)
                    .font(.cosmicCaption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .padding(.horizontal, Cosmic.Spacing.xs)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.cosmicSurface)
                            .overlay(
                                Capsule()
                                    .stroke(data.synastry.overallIntensity.gradient, lineWidth: 1)
                            )
                    )
            }

            // Person B avatar
            avatarView(name: data.pair.nameB, color: Color.planetVenus)
        }
    }

    private func avatarView(name: String, color: Color) -> some View {
        VStack(spacing: Cosmic.Spacing.xxs) {
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
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                )

            Text(name)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }

    // MARK: - Compact Header

    @ViewBuilder
    private func compactHeader(data: CompatibilitySnapshot) -> some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Mini avatars
            HStack(spacing: -8) {
                Circle()
                    .fill(Color.cosmicGold.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(data.pair.nameA.prefix(1)))
                            .font(.cosmicCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )

                Circle()
                    .fill(Color.planetVenus.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(data.pair.nameB.prefix(1)))
                            .font(.cosmicCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    )
            }

            Text("\(data.pair.nameA) & \(data.pair.nameB)")
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            MiniPulseView(pulse: data.now.pulse)
        }
        .padding(.horizontal)
        .padding(.vertical, Cosmic.Spacing.xs)
        .background(Color.cosmicSurface)
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
                onNextTapped: { selectedTab = .journey }
            )
            .padding(.horizontal)

            // Core Connections (top aspects)
            coreConnectionsSection(data: data)
        }
    }

    @ViewBuilder
    private func coreConnectionsSection(data: CompatibilitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Core Connections")
                .font(.cosmicHeadline)
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
            HStack(spacing: Cosmic.Spacing.sm) {
                // Aspect glyphs
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Text(aspect.planetAGlyph)
                        .foregroundStyle(Color.cosmicGold)
                    Text(aspect.aspectGlyph)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(aspect.planetBGlyph)
                        .foregroundStyle(Color.planetVenus)
                }
                .font(.cosmicHeadline)
                .frame(width: 70)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    HStack {
                        Text(aspect.interpretation.title)
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if aspect.isActivatedNow {
                            Image(systemName: "sparkles")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }

                    Text(aspect.interpretation.oneLiner)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Strength indicator
                StrengthBar(strength: aspect.strength, isHarmonious: aspect.isHarmonious)
            }
            .padding(Cosmic.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                    .fill(isSelected ? Color.cosmicSurfaceSecondary : Color.cosmicSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
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
                    .fill(isHarmonious ? Color.cosmicGold : Color.cosmicCopper)
                    .frame(width: CGFloat(strength) * 40, height: 4)
            }

            Text("\(Int(strength * 100))%")
                .font(.cosmicMicro)
                .monospacedDigit()
                .foregroundStyle(Color.cosmicTextTertiary)
        }
    }
}

// MARK: - Next Shift Card

struct NextShiftCard: View {
    let next: NextShift

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color.cosmicTeal)
                Text("Next Shift")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Text("in \(next.daysUntil) days")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Text(next.whatChanges)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)

            Divider()
                .background(Color.cosmicNebula)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.cosmicGold.opacity(0.7))
                Text(next.planForIt)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                        .stroke(Color.cosmicTeal.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Domain Breakdown View

struct DomainBreakdownView: View {
    let domains: [DomainScore]

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Domain Breakdown")
                .font(.cosmicHeadline)
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
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: domain.domain.icon)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicGold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(domain.domain.rawValue)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("\(domain.signA) ↔ \(domain.signB)")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()

            // Intensity indicator with gradient bar
            HStack(spacing: Cosmic.Spacing.xxs) {
                IntensityBar(intensity: domain.intensity)
                    .frame(width: 40, height: 6)

                Text(domain.intensity.displayLabel)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(domain.intensity.color)
            }
        }
    }
}

// MARK: - Intensity Bar

struct IntensityBar: View {
    let intensity: Intensity

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.cosmicNebula.opacity(0.3))

                // Fill based on intensity level
                RoundedRectangle(cornerRadius: 3)
                    .fill(intensity.gradient)
                    .frame(width: geometry.size.width * intensity.fillLevel)
            }
        }
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
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("All Aspects")
                    .font(.cosmicHeadline)
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
        HStack(spacing: Cosmic.Spacing.xs) {
            Text("\(aspect.planetA) \(aspect.aspectGlyph) \(aspect.planetB)")
                .font(.cosmicCaption)
                .monospaced()
                .foregroundStyle(Color.cosmicTextSecondary)

            Spacer()

            Text(String(format: "%.1f°", aspect.orb))
                .font(.cosmicMicro)
                .monospacedDigit()
                .foregroundStyle(Color.cosmicTextTertiary)

            if aspect.isActivatedNow {
                Circle()
                    .fill(Color.cosmicGold)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, Cosmic.Spacing.xxs)
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
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("Charts Comparison")
                    .font(.cosmicHeadline)
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
                ChartsComparisonCircleView(natalA: natalA, natalB: natalB, pair: pair)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
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
            .font(.cosmicCaptionEmphasis)
            .foregroundStyle(Color.cosmicTextTertiary)
            .padding(.bottom, Cosmic.Spacing.xs)

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
                        .foregroundStyle(Color.planetVenus)
                }
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.vertical, Cosmic.Spacing.xxs)

                Divider().background(Color.cosmicNebula.opacity(0.5))
            }
        }
    }
}

private struct ChartsComparisonCircleView: View {
    let natalA: NatalPlacements
    let natalB: NatalPlacements
    let pair: RelationshipPair

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Cosmic.Spacing.md) {
                chart(natalA, title: pair.nameA, color: .cosmicGold)
                chart(natalB, title: pair.nameB, color: .planetVenus)
            }

            VStack(spacing: Cosmic.Spacing.md) {
                chart(natalA, title: pair.nameA, color: .cosmicGold)
                chart(natalB, title: pair.nameB, color: .planetVenus)
            }
        }
    }

    private func chart(_ natal: NatalPlacements, title: String, color: Color) -> some View {
        VStack(spacing: Cosmic.Spacing.xs) {
            Text(title)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(1)

            ChartWheelView(natal: natal, accentColor: color)
                .frame(maxWidth: .infinity)
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicSurface.opacity(0.5))
        )
    }
}

private struct ChartWheelView: View {
    struct WheelBody: Identifiable {
        let id: String
        let planet: Planet
        let placement: Placement
    }

    let natal: NatalPlacements
    let accentColor: Color

    private var bodies: [WheelBody] {
        natal.allPlacements.compactMap { name, placement in
            guard let planet = Planet(rawValue: name) else { return nil }
            return WheelBody(id: name, planet: planet, placement: placement)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2

            ZStack {
                Circle()
                    .stroke(Color.cosmicGold.opacity(0.18), lineWidth: 1)
                    .frame(width: size, height: size)

                // Zodiac wedges + glyphs
                ForEach(0..<12, id: \.self) { i in
                    let startAngle = Angle.degrees(Double(i) * 30 - 90)
                    let midAngle = Angle.degrees(Double(i) * 30 - 75)

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(center: center, radius: radius, angle: startAngle))
                    }
                    .stroke(Color.cosmicNebula.opacity(0.35), lineWidth: 0.5)

                    Text(ZodiacSign.allCases[i].glyph)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .position(point(center: center, radius: radius * 0.86, angle: midAngle))
                }

                // Planet bodies
                ForEach(bodies) { body in
                    let angle = Angle.degrees(body.placement.longitude - 90)
                    let orbitRadius = radius * (0.18 + body.planet.orbitRadius * 0.72)

                    Text(body.planet.glyph)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.cosmicSurface.opacity(0.95))
                        )
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.25), lineWidth: 1)
                        )
                        .position(point(center: center, radius: orbitRadius, angle: angle))
                        .accessibilityLabel("\(body.planet.rawValue) in \(body.placement.sign) \(body.placement.formattedDegree)")
                }

                Circle()
                    .fill(Color.cosmicGold.opacity(0.25))
                    .frame(width: 4, height: 4)
                    .position(x: center.x, y: center.y)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minHeight: 220)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart wheel")
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + Foundation.cos(angle.radians) * radius,
            y: center.y + Foundation.sin(angle.radians) * radius
        )
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
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Header
                    VStack(spacing: Cosmic.Spacing.sm) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            Text(aspect.planetAGlyph)
                                .font(.cosmicDisplay)
                                .foregroundStyle(Color.cosmicGold)
                            Text(aspect.aspectGlyph)
                                .font(.cosmicTitle1)
                                .foregroundStyle(Color.cosmicTextTertiary)
                            Text(aspect.planetBGlyph)
                                .font(.cosmicDisplay)
                                .foregroundStyle(Color.planetVenus)
                        }

                        Text(aspect.interpretation.title)
                            .font(.cosmicTitle2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        if aspect.isActivatedNow {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Currently Active")
                            }
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicGold)
                            .padding(.horizontal, Cosmic.Spacing.sm)
                            .padding(.vertical, Cosmic.Spacing.xxs)
                            .background(Color.cosmicGold.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider().background(Color.cosmicNebula)

                    // One-liner
                    Text(aspect.interpretation.oneLiner)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    // Deep dive
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Deep Dive")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(aspect.interpretation.deepDive)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    // Technical details
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Technical")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)

                        HStack {
                            TechDetail(label: "Aspect", value: aspect.aspectType.rawValue.capitalized)
                            TechDetail(label: "Orb", value: String(format: "%.1f°", aspect.orb))
                            TechDetail(label: "Strength", value: "\(Int(aspect.strength * 100))%")
                        }
                    }
                    .padding()
                    .background(Color.cosmicSurface)
                    .cornerRadius(Cosmic.Radius.soft)
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
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.cosmicCaptionEmphasis)
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
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            Text(share.cardTitle)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(share.cardSentence)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)

            Divider().background(Color.cosmicNebula)

            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Label(share.cardAction, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.cosmicSuccess)
                    Label(share.cardAvoid, systemImage: "xmark.circle.fill")
                        .foregroundStyle(Color.cosmicError.opacity(0.8))
                }
                .font(.cosmicCaption)

                Spacer()
            }

            Text("Based on \(pairNames)'s charts")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card)
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
