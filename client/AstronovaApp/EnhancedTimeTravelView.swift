import SwiftUI

/// Enhanced Time Travel View with interactive Dasha Chakra Wheel,
/// impact analysis, educational content, and comparison features
struct EnhancedTimeTravelView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var viewModel = TimeTravelViewModel()

    @State private var selectedDate: Date = Date()
    @State private var zodiacSystem: ZodiacSystem = .vedic
    @State private var selectedPlanet: DetailedPlanetaryPosition?
    @State private var showDetailCard = false
    @State private var showEducation = false
    @State private var showComparison = false
    @State private var selectedPeriod: DashaPeriod?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date selector
                    DateSelectorView(selectedDate: $selectedDate, onDateChange: {
                        Task {
                            await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager)
                        }
                    })

                    // Zodiac system (affects planetary positions; dashas remain Vedic-based)
                    Picker("Zodiac", selection: $zodiacSystem) {
                        Text("Western").tag(ZodiacSystem.western)
                        Text("Vedic").tag(ZodiacSystem.vedic)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: zodiacSystem) { _, _ in
                        Task { await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager) }
                    }

                    // Planetary motion seeker (moves with the selected date)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Planetary Motion")
                                .font(.cosmicHeadline)
                            Spacer()
                            Button {
                                showEducation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle")
                                    Text("Learn")
                                }
                                .font(.cosmicCalloutEmphasis)
                                .foregroundStyle(Color.cosmicGold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                            }
                            if viewModel.isLoadingPlanets {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                        }

                        if !viewModel.planetaryPositions.isEmpty {
                            PlanetariumCanvasView(
                                planets: viewModel.planetaryPositions,
                                dasha: viewModel.dashaOverlay,
                                year: Calendar.current.component(.year, from: selectedDate),
                                mode: zodiacSystem,
                                showDashaOverlay: viewModel.dashaOverlay != nil
                            )
                            .frame(height: 320)
                        } else if let error = viewModel.planetaryError {
                            ErrorView(message: error)
                        } else {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .scaleEffect(0.9)
                                Text("Loading planetary positions…")
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                            .padding(.vertical, 12)
                        }

                        if !viewModel.planetaryPositions.isEmpty {
                            PlanetPositionsListView(
                                planets: viewModel.planetaryPositions,
                                zodiacSystem: zodiacSystem,
                                onSelect: { selectedPlanet = $0 }
                            )
                        }
                    }
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView("Calculating dasha periods...")
                            .padding()
                    } else if let dashaData = viewModel.dashaData {
                        // Interactive Chakra Wheel
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Dasha Chakra")
                                    .font(.cosmicTitle2)

                                Spacer()

                                Button {
                                    selectedDate = Date()
                                    Task {
                                        await viewModel.loadDashaData(for: Date(), profileManager: auth.profileManager)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                        Text("Now")
                                    }
                                    .font(.cosmicCalloutEmphasis)
                                    .foregroundStyle(Color.cosmicGold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                                }
                            }

                            DashaChakraWheelView(
                                dashaData: dashaData,
                                onPeriodTap: { period in
                                    selectedPeriod = period
                                    showDetailCard = true
                                }
                            )
                            .frame(height: 320)

                            // Narrative
                            Text(dashaData.currentPeriod.narrative)
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                                .padding()
                                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                        }
                        .padding(.horizontal)

                        // Impact Analysis
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Life Impact")
                                    .font(.cosmicHeadline)

                                Spacer()

                                Button {
                                    showComparison.toggle()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.left.arrow.right")
                                        Text("Compare")
                                    }
                                    .font(.cosmicCalloutEmphasis)
                                    .foregroundStyle(showComparison ? Color.cosmicVoid : Color.cosmicGold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(showComparison ? Color.cosmicGold : Color.cosmicGold.opacity(0.15), in: Capsule())
                                }
                            }

                            DashaImpactView(
                                impactScores: dashaData.impactAnalysis.combinedScores,
                                tone: dashaData.impactAnalysis.mahadashaImpact.tone,
                                toneDescription: dashaData.impactAnalysis.mahadashaImpact.toneDescription,
                                comparisonScores: showComparison ? viewModel.comparisonScores : nil
                            )
                        }
                        .padding(.horizontal)

                        // Current Periods Summary
                        CurrentPeriodsView(dashaData: dashaData)
                            .padding(.horizontal)

                        // Transitions (What Changes Next)
                        if let transitions = dashaData.transitions {
                            TransitionsView(transitions: transitions)
                                .padding(.horizontal)
                        }

                        // Keywords
                        KeywordsView(keywords: dashaData.planetaryKeywords)
                            .padding(.horizontal)
                    } else if let error = viewModel.error {
                        if viewModel.isProfileIncomplete {
                            IncompleteProfilePromptView(message: error)
                        } else {
                            ErrorView(message: error)
                                .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Time Travel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEducation = true
                    } label: {
                        Image(systemName: "book.fill")
                            .foregroundStyle(Color.cosmicGold)
                    }
                }
            }
            .sheet(isPresented: $showEducation) {
                if let dashaData = viewModel.dashaData {
                    EducationalDrawerView(dashaData: dashaData)
                } else {
                    NavigationStack {
                        ScrollView {
                            VStack(spacing: 24) {
                                Image(systemName: "sparkles")
                                    .font(.cosmicDisplay)
                                    .foregroundStyle(Color.cosmicGold)

                                Text("Learn About Time Travel")
                                    .font(.cosmicTitle2)

                                Text("Time Travel uses Vedic astrology's Vimshottari Dasha system to show you the planetary periods influencing your life.")
                                    .font(.cosmicBody)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.cosmicTextSecondary)

                                VStack(alignment: .leading, spacing: 16) {
                                    EducationRow(icon: "circle.hexagongrid.fill", title: "Dashas", description: "Planetary periods that shape life themes over years")
                                    EducationRow(icon: "moon.stars.fill", title: "Nakshatras", description: "Lunar mansions that determine your dasha sequence")
                                    EducationRow(icon: "arrow.triangle.2.circlepath", title: "Transits", description: "Current planetary positions affecting your chart")
                                }
                                .padding()
                                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                                Text("Add your birth time and location in your profile to unlock personalized dasha calculations.")
                                    .font(.cosmicCallout)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .navigationTitle("Learn")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showEducation = false
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showDetailCard) {
                if let period = selectedPeriod, let dashaData = viewModel.dashaData {
                    DashaDetailCardView(
                        period: periodToDashaDetails(period, from: dashaData),
                        level: period.level.displayName,
                        strength: strengthForPeriod(period, in: dashaData),
                        keywords: keywordsForPeriod(period, in: dashaData),
                        explanation: dashaData.currentPeriod.narrative
                    )
                }
            }
            .sheet(item: $selectedPlanet) { planet in
                PlanetDetailSheet(
                    planet: planet,
                    currentPeriod: viewModel.dashaData?.currentPeriod
                )
            }
            .task {
                await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager)
            }
            .onChange(of: auth.profileManager.profile.birthTime) { _, _ in
                Task {
                    await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager)
                }
            }
            .onChange(of: auth.profileManager.profile.birthLatitude) { _, _ in
                Task {
                    await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager)
                }
            }
            .onChange(of: auth.profileManager.profile.timezone) { _, _ in
                Task {
                    await viewModel.loadAll(for: selectedDate, zodiacSystem: zodiacSystem, profileManager: auth.profileManager)
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.timeTravelView)
    }

    private func periodToDashaDetails(_ period: DashaPeriod, from data: DashaCompleteResponse) -> DashaCompleteResponse.DashaDetails.Period {
        switch period.level {
        case .mahadasha:
            return data.currentPeriod.mahadasha
        case .antardasha:
            return data.currentPeriod.antardasha ?? data.currentPeriod.mahadasha
        case .pratyantardasha:
            return data.currentPeriod.pratyantardasha ?? data.currentPeriod.mahadasha
        }
    }

    private func strengthForPeriod(_ period: DashaPeriod, in data: DashaCompleteResponse) -> DashaCompleteResponse.ImpactAnalysis.StrengthData? {
        switch period.level {
        case .mahadasha:
            return data.impactAnalysis.mahadashaImpact.strength
        case .antardasha:
            return data.impactAnalysis.antardashaImpact.strength
        case .pratyantardasha:
            return nil
        }
    }

    private func keywordsForPeriod(_ period: DashaPeriod, in data: DashaCompleteResponse) -> [String] {
        switch period.level {
        case .mahadasha:
            return data.planetaryKeywords.mahadasha
        case .antardasha:
            return data.planetaryKeywords.antardasha
        case .pratyantardasha:
            return data.transitions?.impactComparison?.current.keywords ?? data.planetaryKeywords.antardasha
        }
    }
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void

    var body: some View {
        let calendar = Calendar.current
        let monthSymbols = DateFormatter().shortMonthSymbols ?? []

        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Seeker")
                        .font(.cosmicHeadline)
                    Text(selectedDate.formatted(date: .long, time: .omitted))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Button {
                    selectedDate = Date()
                    onDateChange()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text("Now")
                    }
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                }
            }

            // Month navigation
            HStack(spacing: 12) {
                Button {
                    selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    onDateChange()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 36, height: 36)
                        .background(Color.cosmicGold.opacity(0.15), in: Circle())
                }

                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)

                Button {
                    selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    onDateChange()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 36, height: 36)
                        .background(Color.cosmicGold.opacity(0.15), in: Circle())
                }
            }

            // Year scrubber (interactive, discrete)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Year")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Spacer()
                    Text("\(calendar.component(.year, from: selectedDate))")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(calendar.component(.year, from: selectedDate)) },
                        set: { newYear in
                            updateDate(year: Int(newYear), calendar: calendar)
                        }
                    ),
                    in: 1900...2100,
                    step: 1
                )
            }

            // Month chips (fast jumps)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        let isSelected = calendar.component(.month, from: selectedDate) == month
                        Button {
                            updateDate(month: month, calendar: calendar)
                        } label: {
                            Text(monthSymbols.indices.contains(month - 1) ? monthSymbols[month - 1] : "\(month)")
                                .font(.cosmicCaptionEmphasis)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.primary.opacity(0.12) : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .padding(.horizontal)
    }

    private func updateDate(year: Int? = nil, month: Int? = nil, calendar: Calendar) {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        if let year { components.year = year }
        if let month { components.month = month }

        // Clamp day to avoid invalid dates (e.g., Feb 30).
        if let year = components.year, let month = components.month {
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? selectedDate
            if let range = calendar.range(of: .day, in: .month, for: firstOfMonth) {
                let lastDay = range.upperBound - 1
                components.day = min(max(components.day ?? 1, range.lowerBound), lastDay)
            }
        }

        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
            onDateChange()
        }
    }
}

// MARK: - Current Periods View

struct CurrentPeriodsView: View {
    let dashaData: DashaCompleteResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Periods")
                .font(.cosmicHeadline)

            VStack(spacing: 8) {
                PeriodRow(
                    level: "Mahadasha",
                    lord: dashaData.currentPeriod.mahadasha.lord,
                    start: dashaData.currentPeriod.mahadasha.start,
                    end: dashaData.currentPeriod.mahadasha.end
                )

                if let antar = dashaData.currentPeriod.antardasha {
                    PeriodRow(
                        level: "Antardasha",
                        lord: antar.lord,
                        start: antar.start,
                        end: antar.end
                    )
                }

                if let pratyantar = dashaData.currentPeriod.pratyantardasha {
                    PeriodRow(
                        level: "Pratyantardasha",
                        lord: pratyantar.lord,
                        start: pratyantar.start,
                        end: pratyantar.end
                    )
                }
            }
        }
    }
}

struct PeriodRow: View {
    let level: String
    let lord: String
    let start: String
    let end: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(level)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)

                Text(lord)
                    .font(.cosmicHeadline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(formatDate(start)) – \(formatDate(end))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: isoString) else { return isoString }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Transitions View

struct TransitionsView: View {
    let transitions: DashaCompleteResponse.TransitionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What Changes Next")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicInfo)
            }

            Text("Transition insights and upcoming shifts")
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding()
                .background(Color.cosmicInfo.opacity(0.1), in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        }
    }
}

// MARK: - Keywords View

struct KeywordsView: View {
    let keywords: DashaCompleteResponse.PlanetaryKeywords

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Themes")
                .font(.cosmicHeadline)

            VStack(alignment: .leading, spacing: 8) {
                KeywordSection(title: "Mahadasha", keywords: keywords.mahadasha)
                KeywordSection(title: "Antardasha", keywords: keywords.antardasha)
            }
        }
    }
}

struct KeywordSection: View {
    let title: String
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)

            FlowLayout(spacing: 6) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.cosmicCaption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.12), in: Capsule())
                }
            }
        }
    }
}

// MARK: - Educational Drawer

struct EducationalDrawerView: View {
    let dashaData: DashaCompleteResponse

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if dashaData.education != nil {
                        // Calculation explanation
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How Your Dasha Was Calculated", systemImage: "function")
                                .font(.cosmicHeadline)

                            Text("Vimshottari Dasha is based on your Moon's nakshatra at birth. The calculation uses exact astronomical positions to determine planetary periods.")
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        Divider()

                        // Mahadasha guide
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Understanding Mahadasha", systemImage: "circle.hexagongrid.fill")
                                .font(.cosmicHeadline)

                            Text("The Mahadasha is the major planetary period lasting several years. It sets the overall theme and direction of life during that time.")
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        Divider()

                        // Antardasha guide
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Understanding Antardasha", systemImage: "circle.hexagongrid")
                                .font(.cosmicHeadline)

                            Text("The Antardasha is a sub-period within the Mahadasha, lasting months. It modulates the main period's influence with its own planetary themes.")
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }

                    Divider()

                    // General info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("The 9 Planetary Periods", systemImage: "sparkles")
                            .font(.cosmicHeadline)

                        Text("Dashas cycle through 9 planets: Ketu (7y) → Venus (20y) → Sun (6y) → Moon (10y) → Mars (7y) → Rahu (18y) → Jupiter (16y) → Saturn (19y) → Mercury (17y), totaling 120 years.")
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Learn About Dashas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicWarning)

            Text("Unable to Load Data")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(message)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Incomplete Profile Prompt

struct IncompleteProfilePromptView: View {
    let message: String
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        VStack(spacing: Cosmic.Spacing.screen) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicWarning)

            Text("Complete Your Birth Data")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(message)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink {
                ProfileEditView(profileManager: auth.profileManager)
            } label: {
                Label("Complete Birth Data", systemImage: "arrow.right.circle.fill")
                    .font(.cosmicHeadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.cosmicAntiqueGold)
                    .foregroundStyle(Color.cosmicVoid)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                    .accessibilityIdentifier(AccessibilityID.completeBirthDataButton)
            }
            .padding(.horizontal, Cosmic.Spacing.xl)
        }
        .padding()
        .padding(.bottom, 80) // Extra padding for tab bar
        .accessibilityIdentifier(AccessibilityID.incompleteProfilePrompt)
    }
}

// MARK: - View Model

@MainActor
class TimeTravelViewModel: ObservableObject {
    private let api: any APIServicesProtocol

    @Published var dashaData: DashaCompleteResponse?
    @Published var isLoading = false
    @Published var error: String?
    @Published var comparisonScores: DashaCompleteResponse.ImpactScores?
    @Published var isProfileIncomplete = false
    @Published var planetaryPositions: [DetailedPlanetaryPosition] = []
    @Published var isLoadingPlanets = false
    @Published var planetaryError: String?

    init(api: any APIServicesProtocol = APIServices.shared) {
        self.api = api
    }

    var dashaOverlay: DashasResponse? {
        guard let current = dashaData?.currentPeriod else { return nil }
        let mahadasha = DashasResponse.Period(
            lord: current.mahadasha.lord,
            start: current.mahadasha.start,
            end: current.mahadasha.end,
            annotation: ""
        )
        let antardasha = DashasResponse.Period(
            lord: current.antardasha?.lord ?? "—",
            start: current.antardasha?.start,
            end: current.antardasha?.end,
            annotation: ""
        )
        return DashasResponse(mahadasha: mahadasha, antardasha: antardasha)
    }

    func loadAll(for date: Date, zodiacSystem: ZodiacSystem, profileManager: UserProfileManager?) async {
        async let planets: Void = loadPlanetaryPositions(for: date, zodiacSystem: zodiacSystem, profileManager: profileManager)
        async let dashas: Void = loadDashaData(for: date, profileManager: profileManager)
        _ = await (planets, dashas)
    }

    func loadDashaData(for date: Date, profileManager: UserProfileManager?) async {
        isLoading = true
        self.error = nil
        self.isProfileIncomplete = false
        comparisonScores = nil

        guard let profileManager = profileManager else {
            self.error = "No profile available. Please sign in again."
            dashaData = nil
            isLoading = false
            return
        }

        let profile = profileManager.profile

        guard let timezone = profile.timezone,
              let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude else {
            self.error = "Add your birth location and timezone to unlock Time Travel insights."
            self.isProfileIncomplete = true
            dashaData = nil
            isLoading = false
            return
        }

        guard let birthTime = profile.birthTime else {
            self.error = "Add your birth time in profile settings to calculate dashas."
            self.isProfileIncomplete = true
            dashaData = nil
            isLoading = false
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

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
            let response = try await api.fetchCompleteDasha(request: request)
            dashaData = response
            comparisonScores = response.transitions?.impactComparison?.next.impactScores
        } catch let networkError as NetworkError {
            self.error = networkError.errorDescription ?? "Unable to load dasha information."
            dashaData = nil
        } catch {
            self.error = error.localizedDescription
            dashaData = nil
        }

        isLoading = false
    }

    private func loadPlanetaryPositions(for date: Date, zodiacSystem: ZodiacSystem, profileManager: UserProfileManager?) async {
        isLoadingPlanets = true
        planetaryError = nil

        let systemQuery = zodiacSystem == .vedic ? "vedic" : "western"
        let profile = profileManager?.profile

        do {
            let planets = try await api.getPlanetaryPositions(
                for: date,
                latitude: profile?.birthLatitude,
                longitude: profile?.birthLongitude,
                system: systemQuery
            )
            planetaryPositions = planets
        } catch let networkError as NetworkError {
            planetaryError = networkError.errorDescription ?? "Unable to load planetary positions."
            planetaryPositions = []
        } catch {
            planetaryError = error.localizedDescription
            planetaryPositions = []
        }

        isLoadingPlanets = false
    }
}

// MARK: - Planet List (Educational)

private struct PlanetPositionsListView: View {
    let planets: [DetailedPlanetaryPosition]
    let zodiacSystem: ZodiacSystem
    let onSelect: (DetailedPlanetaryPosition) -> Void

    private var sorted: [DetailedPlanetaryPosition] {
        let priority: [String: Int] = [
            "Sun": 0,
            "Moon": 1,
            "Mercury": 2,
            "Venus": 3,
            "Mars": 4,
            "Jupiter": 5,
            "Saturn": 6,
            "Rahu": 7,
            "Ketu": 8,
            "Ascendant": 9,
        ]
        return planets.sorted { (priority[$0.name] ?? 99) < (priority[$1.name] ?? 99) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Planets")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextSecondary)

            VStack(spacing: 10) {
                ForEach(sorted) { planet in
                    Button {
                        onSelect(planet)
                    } label: {
                        HStack(spacing: 12) {
                            Text(planet.symbol)
                                .font(.cosmicHeadline)
                                .frame(width: 28, alignment: .center)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(planet.name)
                                        .font(.subheadline.weight(.semibold))
                                    if planet.retrograde {
                                        Text("Rx")
                                            .font(.cosmicCaptionEmphasis)
                                            .foregroundStyle(Color.cosmicWarning)
                                            .padding(.horizontal, Cosmic.Spacing.xxs)
                                            .padding(.vertical, 2)
                                            .background(Color.cosmicWarning.opacity(0.15), in: Capsule())
                                    }
                                }

                                Text("\(planet.sign) • \(String(format: "%.1f", planet.degree))°")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.cosmicTextSecondary)

                                if let significance = planet.significance, !significance.isEmpty {
                                    Text(significance)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .padding(12)
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Education Row

private struct EducationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicGold)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.cosmicHeadline)
                Text(description)
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
    }
}

private struct PlanetDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let planet: DetailedPlanetaryPosition
    let currentPeriod: DashaCompleteResponse.CurrentPeriod?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Text(planet.symbol)
                            .font(.system(size: 44))
                            .frame(width: 56, height: 56)
                            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(planet.name)
                                .font(.cosmicTitle2)
                            Text("\(planet.sign) • \(String(format: "%.1f", planet.degree))°")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                        Spacer()
                        if planet.retrograde {
                            Text("Retrograde")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicWarning)
                                .padding(.horizontal, Cosmic.Spacing.xs)
                                .padding(.vertical, Cosmic.Spacing.xxs)
                                .background(Color.cosmicWarning.opacity(0.15), in: Capsule())
                        }
                    }

                    if let significance = planet.significance, !significance.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meaning")
                                .font(.cosmicHeadline)
                            Text(significance)
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
                    }

                    if let currentPeriod {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Context (Dashas)")
                                .font(.cosmicHeadline)

                            Text("Mahadasha: \(currentPeriod.mahadasha.lord) • Antardasha: \(currentPeriod.antardasha?.lord ?? "—")")
                                .font(.subheadline.weight(.semibold))

                            Text("Use this planet’s transit meaning alongside your current dasha themes to decide what to lean into now.")
                                .font(.cosmicBody)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                        .padding()
                        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
                    }
                }
                .padding()
            }
            .navigationTitle("Planet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Planetarium Canvas View

/// A canvas view displaying planetary positions in a circular zodiac wheel
struct PlanetariumCanvasView: View {
    let planets: [DetailedPlanetaryPosition]
    let dasha: DashasResponse?
    let year: Int
    let mode: ZodiacSystem
    let showDashaOverlay: Bool

    private let zodiacSigns = ["Ari", "Tau", "Gem", "Can", "Leo", "Vir", "Lib", "Sco", "Sag", "Cap", "Aqu", "Pis"]

    private let planetColors: [String: Color] = [
        "sun": .yellow,
        "moon": .cyan,
        "mercury": .green,
        "venus": .pink,
        "mars": .red,
        "jupiter": .orange,
        "saturn": .brown,
        "rahu": .purple,
        "ketu": .indigo
    ]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Background
                Circle()
                    .fill(Color.cosmicBackground.opacity(0.3))
                    .frame(width: size, height: size)

                // Zodiac ring
                ForEach(0..<12, id: \.self) { index in
                    let angle = Angle(degrees: Double(index) * 30 - 90)
                    let radius = size * 0.42
                    let x = center.x + cos(angle.radians) * radius
                    let y = center.y + sin(angle.radians) * radius

                    Text(zodiacSigns[index])
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .position(x: x, y: y)
                }

                // Planet positions
                ForEach(planets) { planet in
                    let totalDegree = signToDegree(planet.sign) + planet.degree
                    let angle = Angle(degrees: totalDegree - 90)
                    let radius = size * 0.32
                    let x = center.x + cos(angle.radians) * radius
                    let y = center.y + sin(angle.radians) * radius
                    let color = planetColors[planet.name.lowercased()] ?? .white

                    VStack(spacing: 2) {
                        Text(planet.symbol)
                            .font(.system(size: 18))
                        if planet.retrograde {
                            Text("R")
                                .font(.cosmicMicro)
                                .foregroundStyle(.red)
                        }
                    }
                    .foregroundStyle(color)
                    .position(x: x, y: y)
                }

                // Dasha overlay (if enabled)
                if showDashaOverlay, let dasha = dasha {
                    VStack(spacing: 4) {
                        Text(dasha.mahadasha.lord)
                            .font(.cosmicCaption)
                            .fontWeight(.semibold)
                        Text(dasha.antardasha.lord)
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .padding(8)
                    .background(Color.cosmicSurface.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .position(x: center.x, y: center.y)
                }
            }
        }
    }

    private func signToDegree(_ sign: String) -> Double {
        let signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo",
                     "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]
        let index = signs.firstIndex(of: sign.lowercased()) ?? 0
        return Double(index) * 30
    }
}
