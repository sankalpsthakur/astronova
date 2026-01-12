import SwiftUI
import Combine

// MARK: - Unified Time Travel View
// North Star: "Pick any month/year → instantly see what changes, why it matters, what to do next."

struct UnifiedTimeTravelView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var state = TimeTravelViewState()

    @State private var showNowSheet = false
    @State private var showNextSheet = false
    @State private var showActSheet = false
    @State private var showPlanetSheet = false
    @State private var showDashaSheet = false

    private var timeTravelLockMessage: String? {
        let profile = auth.profileManager.profile

        if profile.timezone == nil || profile.birthLatitude == nil || profile.birthLongitude == nil {
            return "Add your birth location and timezone to unlock Time Travel insights."
        }
        if profile.birthTime == nil {
            return "Add your birth time in profile settings to calculate dashas."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let lockMessage = timeTravelLockMessage {
                    IncompleteProfilePromptView(message: lockMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.cosmicBackground.ignoresSafeArea())
                } else {
                    ScrollView {
                        VStack(spacing: Cosmic.Spacing.lg) {
                            TimeSeeker(
                                selectedDate: $state.targetDate,
                                onDateChanged: { state.onDateScrubbing() },
                                onDragEnded: { state.onDateCommit() },
                                onInsightTapped: { insight in
                                    guard let element = insight.element else { return }
                                    withAnimation(.cosmicSpring) {
                                        state.selectedElement = element
                                    }
                                },
                                insights: state.scrubFeedback.insights,
                                summary: state.scrubFeedback.summary
                            )
                            .padding(.horizontal)

                            if let error = state.errorMessage {
                                Text(error)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                                    .padding(.horizontal)
                            }

                            if let snapshot = state.displaySnapshot {
                                CosmicMapView(
                                    snapshot: snapshot,
                                    selectedElement: $state.selectedElement,
                                    onElementTapped: { element in
                                        handleElementTapped(element)
                                    }
                                )
                                .frame(height: 350)
                                .padding(.horizontal)
                                .overlay(alignment: .top) {
                                    if state.isLoading {
                                        loadingOverlay
                                    }
                                }

                                if let selected = state.selectedElement {
                                    tooltipView(for: selected, snapshot: snapshot)
                                        .padding(.horizontal)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }

                                MeaningStack(
                                    snapshot: snapshot,
                                    isCompact: false,
                                    onNowTapped: { showNowSheet = true },
                                    onNextTapped: { showNextSheet = true },
                                    onActTapped: { showActSheet = true }
                                )
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: Cosmic.Spacing.sm) {
                                    ProgressView()
                                    if let error = state.errorMessage {
                                        Text(error)
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text("Calculating your snapshot…")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.vertical)
                    }
                    .background(Color.cosmicBackground)
                    .task {
                        await state.bootstrap(profile: auth.profileManager.profile)
                    }
                    .onChange(of: auth.profileManager.profile.birthTime) { _, _ in
                        Task { await state.bootstrap(profile: auth.profileManager.profile) }
                    }
                    .onChange(of: auth.profileManager.profile.birthLatitude) { _, _ in
                        Task { await state.bootstrap(profile: auth.profileManager.profile) }
                    }
                    .onChange(of: auth.profileManager.profile.birthLongitude) { _, _ in
                        Task { await state.bootstrap(profile: auth.profileManager.profile) }
                    }
                    .onChange(of: auth.profileManager.profile.timezone) { _, _ in
                        Task { await state.bootstrap(profile: auth.profileManager.profile) }
                    }
                    .onChange(of: auth.profileManager.profile.birthDate) { _, _ in
                        Task { await state.bootstrap(profile: auth.profileManager.profile) }
                    }
                }
            }
            .navigationTitle("Time Travel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "book.fill")
                    }
                }
            }
            .sheet(isPresented: $showNowSheet) {
                if let snapshot = state.displaySnapshot {
                    NowDetailSheet(snapshot: snapshot)
                }
            }
            .sheet(isPresented: $showNextSheet) {
                if let snapshot = state.displaySnapshot {
                    NextDetailSheet(snapshot: snapshot)
                }
            }
            .sheet(isPresented: $showActSheet) {
                if let snapshot = state.displaySnapshot {
                    ActDetailSheet(snapshot: snapshot)
                }
            }
            .sheet(isPresented: $showPlanetSheet) {
                if let snapshot = state.displaySnapshot,
                   case .planet(let id) = state.selectedElement,
                   let planet = snapshot.planets.first(where: { $0.id == id }) {
                    PlanetDetailSheetV2(planet: planet, snapshot: snapshot)
                }
            }
            .sheet(isPresented: $showDashaSheet) {
                if let snapshot = state.displaySnapshot,
                   case .dashaLord(let lord) = state.selectedElement {
                    DashaLordDetailSheet(lord: lord, snapshot: snapshot)
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card)
            .fill(Color.cosmicSurface)
            .overlay(
                HStack(spacing: Cosmic.Spacing.xs) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Updating...")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            )
            .frame(height: 40)
            .padding(.horizontal, 100)
            .padding(.top, 20)
            .transition(.opacity)
    }

    // MARK: - Tooltip View

    @ViewBuilder
    private func tooltipView(for element: CosmicElement, snapshot: TimeTravelSnapshot) -> some View {
        switch element {
        case .planet(let id):
            if let planet = snapshot.planets.first(where: { $0.id == id }) {
                planetTooltip(planet)
            }
        case .dashaLord(let lord):
            dashaTooltip(lord)
        case .aspect(let p1, let p2):
            if let aspect = snapshot.aspects.first(where: { $0.planet1 == p1 && $0.planet2 == p2 }) {
                aspectTooltip(aspect)
            }
        }
    }

    private func planetTooltip(_ planet: PlanetState) -> some View {
        Button {
            showPlanetSheet = true
        } label: {
            HStack(spacing: Cosmic.Spacing.sm) {
                Text(planet.symbol)
                    .font(.cosmicTitle2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(planet.name)
                            .font(.cosmicHeadline)
                        if planet.isRetrograde {
                            Text("Rx")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.cosmicWarning)
                        }
                    }
                    Text("\(planet.sign) \(String(format: "%.1f", planet.degree))°")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                // Role badges
                VStack(spacing: Cosmic.Spacing.xxs) {
                    if planet.isDashaLord {
                        Text("Mahadasha")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cosmicAmethyst.opacity(0.2), in: Capsule())
                    }
                    if planet.isAntardashaLord {
                        Text("Antardasha")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cosmicInfo.opacity(0.2), in: Capsule())
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding()
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        }
        .buttonStyle(.plain)
    }

    private func dashaTooltip(_ lord: String) -> some View {
        Button {
            showDashaSheet = true
        } label: {
            HStack(spacing: Cosmic.Spacing.sm) {
                // Find planet for symbol
                let symbol = state.displaySnapshot?.planets.first { $0.name == lord }?.symbol ?? "☆"
                Text(symbol)
                    .font(.cosmicTitle2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(lord) Dasha")
                        .font(.cosmicHeadline)

                    if state.displaySnapshot?.currentDasha.mahadasha.lord == lord {
                        Text("Current Mahadasha • \(state.displaySnapshot?.currentDasha.mahadasha.theme ?? "")")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    } else if state.displaySnapshot?.currentDasha.antardasha.lord == lord {
                        Text("Current Antardasha • \(state.displaySnapshot?.currentDasha.antardasha.theme ?? "")")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding()
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        }
        .buttonStyle(.plain)
    }

    private func aspectTooltip(_ aspect: ActiveAspect) -> some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(aspect.planet1.capitalized) \(aspect.type.rawValue) \(aspect.planet2.capitalized)")
                    .font(.cosmicHeadline)

                Text(aspect.significance)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f° orb", aspect.orb))
                    .font(.cosmicCaption.monospacedDigit())

                Text(aspect.isApplying ? "Applying" : "Separating")
                    .font(.cosmicMicro)
                    .foregroundStyle(aspect.isApplying ? Color.cosmicSuccess : Color.cosmicWarning)
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
    }

    // MARK: - Actions

    private func handleElementTapped(_ element: CosmicElement) {
        CosmicHaptics.medium()

        switch element {
        case .planet:
            showPlanetSheet = true
        case .dashaLord:
            showDashaSheet = true
        case .aspect:
            break
        }
    }
}

// MARK: - View State

@MainActor
class TimeTravelViewState: ObservableObject {
    @Published var targetDate: Date = Date()
    @Published var selectedElement: CosmicElement?
    @Published var isLoading: Bool = false

    // Display snapshot (shows cached/interpolated data while loading)
    @Published var displaySnapshot: TimeTravelSnapshot?
    @Published var scrubFeedback: ScrubFeedback = ScrubFeedback(insights: [], summary: nil)
    @Published var errorMessage: String?

    private let api = APIServices.shared
    private var profile: UserProfile?

    private var snapshotCache: [String: TimeTravelSnapshot] = [:]
    private var planetsCache: [String: [PlanetState]] = [:]
    private var snapshotCacheOrder: [String] = []
    private var planetsCacheOrder: [String] = []
    private let maxSnapshotCacheEntries = 24
    private let maxPlanetsCacheEntries = 24

    // Debounce
    private var debounceTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 200_000_000 // 200ms in nanoseconds
    private let systemQuery: String = "vedic"

    func bootstrap(profile: UserProfile) async {
        let shouldRefresh = profileDidChange(from: self.profile, to: profile)
        self.profile = profile
        if shouldRefresh {
            resetCaches()
            await fetchSnapshot(for: targetDate)
            return
        }
        guard displaySnapshot == nil else { return }
        await fetchSnapshot(for: targetDate)
    }

    func onDateScrubbing() {
        // Cancel any pending fetch
        debounceTask?.cancel()
        fetchTask?.cancel()
        errorMessage = nil

        guard let previous = displaySnapshot else { return }
        guard let key = dateKey(for: targetDate) else { return }

        if let cached = snapshotCache[key] {
            touchKey(key, order: &snapshotCacheOrder)
            displaySnapshot = cached
            scrubFeedback = TimeTravelSnapshot.scrubFeedback(from: previous, to: cached)
            return
        }

        if let planets = planetsCache[key] {
            touchKey(key, order: &planetsCacheOrder)
            var nextPlanets = planets
            // Carry dasha highlighting forward while user is scrubbing.
            for idx in nextPlanets.indices {
                if nextPlanets[idx].name == previous.currentDasha.mahadasha.lord { nextPlanets[idx].isDashaLord = true }
                if nextPlanets[idx].name == previous.currentDasha.antardasha.lord { nextPlanets[idx].isAntardashaLord = true }
            }

            let aspects = TimeTravelSnapshot.computeAspects(planets: nextPlanets)
            let transitions = recomputeDaysUntil(previous.nextTransitions, from: targetDate)
            let next = TimeTravelSnapshot(
                targetDate: targetDate,
                planets: nextPlanets,
                currentDasha: previous.currentDasha,
                aspects: aspects,
                now: previous.now,
                nextTransitions: transitions,
                act: previous.act
            )

            displaySnapshot = next
            scrubFeedback = TimeTravelSnapshot.scrubFeedback(from: previous, to: next)
        }
    }

    private func profileDidChange(from oldProfile: UserProfile?, to newProfile: UserProfile) -> Bool {
        guard let oldProfile else { return true }
        return oldProfile.birthDate != newProfile.birthDate ||
            oldProfile.birthTime != newProfile.birthTime ||
            oldProfile.birthLatitude != newProfile.birthLatitude ||
            oldProfile.birthLongitude != newProfile.birthLongitude ||
            oldProfile.timezone != newProfile.timezone
    }

    private func resetCaches() {
        snapshotCache.removeAll()
        planetsCache.removeAll()
        snapshotCacheOrder.removeAll()
        planetsCacheOrder.removeAll()
        displaySnapshot = nil
        scrubFeedback = ScrubFeedback(insights: [], summary: nil)
        errorMessage = nil
    }

    func onDateCommit() {
        // Debounce: wait before fetching
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceDelay)

                // If not cancelled, fetch real data
                let committedDate = targetDate
                fetchTask?.cancel()
                fetchTask = Task {
                    await fetchSnapshot(for: committedDate)
                }
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }

    private func fetchSnapshot(for date: Date) async {
        if Task.isCancelled { return }
        guard let profile else { return }
        guard let timezone = profile.timezone,
              let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let birthTime = profile.birthTime else { return }

        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: timezone) ?? .current

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: timezone) ?? .current

        let request = DashaCompleteRequest(
            birthData: .init(
                date: dateFormatter.string(from: profile.birthDate),
                time: timeFormatter.string(from: birthTime),
                timezone: timezone,
                latitude: latitude,
                longitude: longitude
            ),
            targetDate: dateFormatter.string(from: date),
            includeTransitions: true,
            includeEducation: true
        )

        do {
            async let planetsTask = api.getPlanetaryPositions(for: date, latitude: latitude, longitude: longitude, system: systemQuery)
            async let dashaTask = api.fetchCompleteDasha(request: request)

            let (planetPositions, dashaResponse) = try await (planetsTask, dashaTask)
            try Task.checkCancellation()
            let planetStates = sortPlanets(planetPositions.map(TimeTravelSnapshot.planetState(from:)))

            if let key = dateKey(for: date) {
                let snapshot = TimeTravelSnapshot.build(targetDate: date, planets: planetStates, dashaResponse: dashaResponse)
                cachePlanets(planetStates, for: key)
                cacheSnapshot(snapshot, for: key)

                if let previous = displaySnapshot {
                    scrubFeedback = TimeTravelSnapshot.scrubFeedback(from: previous, to: snapshot)
                } else {
                    scrubFeedback = ScrubFeedback(insights: [], summary: nil)
                }

                displaySnapshot = snapshot
                selectedElement = nil
            }

            prefetchPlanets(around: date, latitude: latitude, longitude: longitude)
        } catch is CancellationError {
            // Ignore cancellations from rapid scrubbing.
        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func prefetchPlanets(around date: Date, latitude: Double, longitude: Double) {
        let calendar = Calendar.current

        let offsets = [-3, -2, -1, 1, 2, 3]
        Task { [weak self] in
            guard let self else { return }
            for offset in offsets {
                guard let d = calendar.date(byAdding: .month, value: offset, to: date) else { continue }
                guard let key = self.dateKey(for: d) else { continue }
                let alreadyCached = self.planetsCache[key] != nil
                if alreadyCached { continue }

                do {
                    let positions = try await self.api.getPlanetaryPositions(for: d, latitude: latitude, longitude: longitude, system: self.systemQuery)
                    let states = self.sortPlanets(positions.map(TimeTravelSnapshot.planetState(from:)))
                    self.cachePlanets(states, for: key)
                } catch {
                    // Best-effort prefetch.
                }
            }
        }
    }

    private func cacheSnapshot(_ snapshot: TimeTravelSnapshot, for key: String) {
        snapshotCache[key] = snapshot
        touchKey(key, order: &snapshotCacheOrder)
        trimCache(&snapshotCache, order: &snapshotCacheOrder, maxEntries: maxSnapshotCacheEntries)
    }

    private func cachePlanets(_ planets: [PlanetState], for key: String) {
        planetsCache[key] = planets
        touchKey(key, order: &planetsCacheOrder)
        trimCache(&planetsCache, order: &planetsCacheOrder, maxEntries: maxPlanetsCacheEntries)
    }

    private func touchKey(_ key: String, order: inout [String]) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.append(key)
    }

    private func trimCache<T>(
        _ cache: inout [String: T],
        order: inout [String],
        maxEntries: Int
    ) {
        while order.count > maxEntries {
            let key = order.removeFirst()
            cache.removeValue(forKey: key)
        }
    }

    private func dateKey(for date: Date) -> String? {
        guard let profile else { return nil }
        guard let timezone = profile.timezone else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: timezone) ?? .current
        return formatter.string(from: date)
    }

    private func recomputeDaysUntil(_ transitions: [NextTransition], from date: Date) -> [NextTransition] {
        let calendar = Calendar.current
        return transitions.map { t in
            let days = max(0, calendar.dateComponents([.day], from: date, to: t.targetDate).day ?? t.daysUntil)
            return NextTransition(
                transitionType: t.transitionType,
                targetDate: t.targetDate,
                daysUntil: days,
                whatShifts: t.whatShifts,
                fromLord: t.fromLord,
                toLord: t.toLord
            )
        }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    private func sortPlanets(_ planets: [PlanetState]) -> [PlanetState] {
        let priority: [String: Int] = [
            "sun": 0,
            "moon": 1,
            "mercury": 2,
            "venus": 3,
            "mars": 4,
            "jupiter": 5,
            "saturn": 6,
            "rahu": 7,
            "ketu": 8,
            "uranus": 9,
            "neptune": 10,
            "pluto": 11,
            "ascendant": 12,
        ]
        return planets.sorted { (priority[$0.id] ?? 99) < (priority[$1.id] ?? 99) }
    }
}

// MARK: - Detail Sheets

struct NowDetailSheet: View {
    let snapshot: TimeTravelSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Dasha header
                    HStack(spacing: Cosmic.Spacing.md) {
                        VStack {
                            Text(snapshot.currentDasha.mahadasha.symbol)
                                .font(.cosmicDisplay)
                            Text("Mahadasha")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        Image(systemName: "circle.fill")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)

                        VStack {
                            Text(snapshot.currentDasha.antardasha.symbol)
                                .font(.cosmicDisplay)
                            Text("Antardasha")
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                    // Theme
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Current Energy")
                            .font(.cosmicHeadline)
                        Text(snapshot.now.theme)
                            .font(.cosmicTitle2)
                    }

                    // Extended detail
                    if let detail = snapshot.now.expandedDetail {
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                            Text("Understanding This Phase")
                                .font(.cosmicHeadline)
                            Text(detail)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }

                    // Progress bars
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        Text("Cycle Progress")
                            .font(.cosmicHeadline)

                        ProgressRow(
                            label: "Mahadasha",
                            sublabel: snapshot.currentDasha.mahadasha.lord,
                            progress: snapshot.currentDasha.mahadashaProgress
                        )

                        ProgressRow(
                            label: "Antardasha",
                            sublabel: snapshot.currentDasha.antardasha.lord,
                            progress: snapshot.currentDasha.antardashaProgress
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Current Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ProgressRow: View {
    let label: String
    let sublabel: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            HStack {
                Text(label)
                    .font(.cosmicCallout)
                Spacer()
                Text(sublabel)
                    .font(.subheadline.weight(.medium))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cosmicTextSecondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cosmicGold)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)

            Text("\(Int(progress * 100))% complete")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
    }
}

struct NextDetailSheet: View {
    let snapshot: TimeTravelSnapshot
    @Environment(\.dismiss) private var dismiss

    private var nextTransition: NextTransition? {
        snapshot.nextTransitions.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    if let next = nextTransition {
                        // Countdown hero
                        VStack(spacing: Cosmic.Spacing.xs) {
                            Text(next.countdownShort)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("until \(next.transitionType.rawValue.lowercased()) shift")
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()

                        // Transition details
                        HStack(spacing: Cosmic.Spacing.lg) {
                            VStack {
                                Text("From")
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                Text(next.fromLord)
                                    .font(.title2.weight(.bold))
                            }

                            Image(systemName: "arrow.right")
                                .font(.cosmicTitle2)
                                .foregroundStyle(Color.cosmicTextSecondary)

                            VStack {
                                Text("To")
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                Text(next.toLord)
                                    .font(.title2.weight(.bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                        // What shifts
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                            Text("What Changes")
                                .font(.cosmicHeadline)
                            Text(next.whatShifts)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        // Timeline list
                        if snapshot.nextTransitions.count > 1 {
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                                Text("Upcoming Shifts")
                                    .font(.cosmicHeadline)

                                ForEach(snapshot.nextTransitions) { transition in
                                    HStack {
                                        Text(transition.transitionType.rawValue)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                        Spacer()
                                        Text("\(transition.fromLord) → \(transition.toLord)")
                                            .font(.subheadline.weight(.medium))
                                        Spacer()
                                        Text(transition.countdownShort)
                                            .font(.cosmicCaption.monospacedDigit())
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .padding()
                            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
                        }
                    } else {
                        ContentUnavailableView("No upcoming transitions", systemImage: "calendar.badge.exclamationmark")
                    }
                }
                .padding()
            }
            .navigationTitle("Next Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ActDetailSheet: View {
    let snapshot: TimeTravelSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Do
                    ActionCard(
                        type: .do,
                        content: snapshot.act.doThis
                    )

                    // Avoid
                    ActionCard(
                        type: .avoid,
                        content: snapshot.act.avoidThis
                    )

                    // Why
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Why This Guidance")
                            .font(.cosmicHeadline)
                        Text(snapshot.act.whyExplanation)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .padding()
                    .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
                }
                .padding()
            }
            .navigationTitle("Action Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ActionCard: View {
    enum ActionType {
        case `do`, avoid

        var icon: String {
            switch self {
            case .do: return "checkmark.circle.fill"
            case .avoid: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .do: return .cosmicSuccess
            case .avoid: return .cosmicError
            }
        }

        var label: String {
            switch self {
            case .do: return "Do This"
            case .avoid: return "Avoid This"
            }
        }
    }

    let type: ActionType
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.title)
                .foregroundStyle(type.color)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text(type.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cosmicTextSecondary)
                Text(content)
                    .font(.cosmicBody)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color.opacity(0.1), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
    }
}

struct PlanetDetailSheetV2: View {
    let planet: PlanetState
    let snapshot: TimeTravelSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Planet header
                    HStack(spacing: Cosmic.Spacing.md) {
                        Text(planet.symbol)
                            .font(.system(size: 56))

                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                            HStack {
                                Text(planet.name)
                                    .font(.largeTitle.weight(.bold))
                                if planet.isRetrograde {
                                    Text("Retrograde")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.cosmicWarning)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.cosmicWarning.opacity(0.2), in: Capsule())
                                }
                            }

                            Text("\(planet.sign) • \(String(format: "%.2f", planet.degree))°")
                                .font(.cosmicTitle2)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                    .padding()
                    .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                    // Dasha role
                    if planet.isDashaLord || planet.isAntardashaLord {
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                            Text("Dasha Role")
                                .font(.cosmicHeadline)

                            if planet.isDashaLord {
                                Label("Current Mahadasha Lord", systemImage: "star.fill")
                                    .foregroundStyle(Color.cosmicAmethyst)
                            }
                            if planet.isAntardashaLord {
                                Label("Current Antardasha Lord", systemImage: "star.fill")
                                    .foregroundStyle(Color.cosmicInfo)
                            }
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                    }

                    // Active aspects
                    let relevantAspects = snapshot.aspects.filter { $0.planet1 == planet.id || $0.planet2 == planet.id }
                    if !relevantAspects.isEmpty {
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                            Text("Active Aspects")
                                .font(.cosmicHeadline)

                            ForEach(relevantAspects) { aspect in
                                let otherPlanet = aspect.planet1 == planet.id ? aspect.planet2 : aspect.planet1
                                HStack {
                                    Text(aspect.type.rawValue.capitalized)
                                        .font(.subheadline.weight(.medium))
                                    Text("to \(otherPlanet.capitalized)")
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f° orb", aspect.orb))
                                        .font(.cosmicCaption.monospacedDigit())
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                    }
                }
                .padding()
            }
            .navigationTitle(planet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DashaLordDetailSheet: View {
    let lord: String
    let snapshot: TimeTravelSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Find planet for this lord
                    if let planet = snapshot.planets.first(where: { $0.name == lord }) {
                        HStack(spacing: Cosmic.Spacing.md) {
                            Text(planet.symbol)
                                .font(.system(size: 56))

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                                Text("\(lord) Dasha")
                                    .font(.largeTitle.weight(.bold))

                                if snapshot.currentDasha.mahadasha.lord == lord {
                                    Text("Current Mahadasha")
                                        .foregroundStyle(Color.cosmicAmethyst)
                                } else if snapshot.currentDasha.antardasha.lord == lord {
                                    Text("Current Antardasha")
                                        .foregroundStyle(Color.cosmicInfo)
                                }
                            }
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                        // Where this planet is now
                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                            Text("Where \(lord) Is Now")
                                .font(.cosmicHeadline)

                            Text("\(planet.sign) at \(String(format: "%.1f", planet.degree))°")
                                .font(.cosmicTitle2)

                            if planet.isRetrograde {
                                Label("Currently retrograde", systemImage: "arrow.uturn.backward")
                                    .foregroundStyle(Color.cosmicWarning)
                            }
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                    }
                }
                .padding()
            }
            .navigationTitle("\(lord) Dasha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
