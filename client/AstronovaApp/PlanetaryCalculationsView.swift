import SwiftUI
import CoreLocation
import Foundation

struct PlanetaryCalculationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var currentStep = 0
    @State private var animateElements = false
    
    // User input states
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedLocation = ""
    @State private var searchText = ""
    @State private var locationResults: [LocationResult] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSearching = false
    
    // Chart calculation states
    @State private var calculatedPositions: [String: DetailedPlanetaryPosition] = [:]
    @State private var isCalculating = false
    @State private var calculationProgress: Double = 0.0
    @State private var currentCalculationStep = ""
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic Background
                cosmicBackground
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Step Content
                    TabView(selection: $currentStep) {
                        // Step 1: Birth Date Input
                        BirthDateStepView(selectedDate: $selectedDate)
                            .tag(0)
                        
                        // Step 2: Birth Time Input
                        BirthTimeStepView(selectedTime: $selectedTime)
                            .tag(1)
                        
                        // Step 3: Location Input with Autocomplete
                        LocationStepView(
                            searchText: $searchText,
                            locationResults: $locationResults,
                            selectedLocation: $selectedLocation,
                            selectedCoordinate: $selectedCoordinate,
                            isSearching: $isSearching
                        )
                        .tag(2)
                        
                        // Step 4: Chart Calculation Process
                        CalculationStepView(
                            isCalculating: $isCalculating,
                            calculationProgress: $calculationProgress,
                            currentStep: $currentCalculationStep,
                            calculatedPositions: $calculatedPositions,
                            birthDate: selectedDate,
                            birthTime: selectedTime,
                            coordinate: selectedCoordinate
                        )
                        .tag(3)
                        
                        // Step 5: Results & Chart Visualization
                        ResultsStepView(
                            positions: calculatedPositions,
                            birthDate: selectedDate,
                            birthTime: selectedTime,
                            location: selectedLocation
                        )
                        .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Navigation Controls
                    navigationControls
                }
            }
            .navigationTitle("Build Your Chart")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                initializeWithUserProfile()
                withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                    animateElements = true
                }
            }
        }
    }
    
    // MARK: - Background
    private var cosmicBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemIndigo).opacity(0.9),
                Color(.systemPurple).opacity(0.7),
                Color(.systemBlue).opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Astrological Calculations")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            // Progress Bar
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(y: 2)
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Navigation Controls
    private var navigationControls: some View {
        HStack {
            Button(action: previousStep) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.headline)
                .foregroundStyle(currentStep > 0 ? .white : .white.opacity(0.3))
            }
            .disabled(currentStep == 0)
            
            Spacer()
            
            Button(action: nextStep) {
                HStack {
                    Text(canProceed ? (currentStep == totalSteps - 1 ? "Finish" : "Next") : "Complete This Step")
                    if currentStep < totalSteps - 1 && canProceed {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .foregroundStyle(canProceed ? .white : .white.opacity(0.5))
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Date always valid
        case 1: return true // Time always valid
        case 2: return selectedCoordinate != nil // Location selected
        case 3: return !calculatedPositions.isEmpty // Calculation complete
        case 4: return true // Results step
        default: return false
        }
    }
    
    private func planetSymbol(for planet: String) -> String {
        switch planet {
        case "Sun": return "☉"
        case "Moon": return "☽"
        case "Mercury": return "☿"
        case "Venus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturn": return "♄"
        case "Uranus": return "♅"
        case "Neptune": return "♆"
        case "Pluto": return "♇"
        default: return "●"
        }
    }
    
    private func planetSignificance(for planet: String) -> String {
        switch planet {
        case "Sun": return "Core identity and vitality"
        case "Moon": return "Emotions and intuition"
        case "Mercury": return "Communication and thinking"
        case "Venus": return "Love and values"
        case "Mars": return "Energy and action"
        case "Jupiter": return "Growth and wisdom"
        case "Saturn": return "Structure and discipline"
        case "Uranus": return "Innovation and change"
        case "Neptune": return "Dreams and spirituality"
        case "Pluto": return "Transformation and power"
        default: return "Planetary influence"
        }
    }
    
    private func initializeWithUserProfile() {
        // Pre-fill with user's profile data if available
        selectedDate = profileManager.profile.birthDate
        if let birthTime = profileManager.profile.birthTime {
            selectedTime = birthTime
        }
        if let place = profileManager.profile.birthPlace {
            selectedLocation = place
        }
        if let coordinates = profileManager.profile.birthCoordinates {
            selectedCoordinate = coordinates
        }
        
        // Smart step initialization: skip to calculation if profile is complete
        let hasCompleteBirthData = profileManager.profile.birthTime != nil && 
                                  profileManager.profile.birthPlace != nil && 
                                  profileManager.profile.birthCoordinates != nil
        
        if hasCompleteBirthData {
            // User has complete birth data - skip to calculation step (3/5)
            currentStep = 3
        } else if profileManager.profile.birthTime != nil {
            // User has date and time but missing location - skip to location step (2/5)
            currentStep = 2
        }
        // Otherwise start from step 0 (date input)
    }
    
    private func previousStep() {
        guard currentStep > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    private func nextStep() {
        guard canProceed else { return }
        
        if currentStep < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
            
            // Auto-start calculation when reaching step 4
            if currentStep == 3 && !isCalculating && calculatedPositions.isEmpty {
                startChartCalculation()
            }
        } else {
            // Save to profile and dismiss
            saveToProfile()
            dismiss()
        }
    }
    
    private func startChartCalculation() {
        guard let coordinate = selectedCoordinate else { return }
        
        isCalculating = true
        calculationProgress = 0.0
        calculatedPositions.removeAll()
        
        Task {
            await performChartCalculation(coordinate: coordinate)
        }
    }
    
    private func performChartCalculation(coordinate: CLLocationCoordinate2D) async {
        let steps = [
            ("Calculating Julian Day Number...", "Converting birth date to astronomical time"),
            ("Computing Local Sidereal Time...", "Determining Earth's rotation relative to stars"),
            ("Determining Planetary Positions...", "Calculating where planets appear in the sky"),
            ("Computing House Cusps...", "Dividing the sky into 12 astrological houses"),
            ("Calculating Aspects...", "Finding angular relationships between planets"),
            ("Generating Chart Data...", "Finalizing your personalized chart")
        ]
        
        for (index, (step, _)) in steps.enumerated() {
            await MainActor.run {
                currentCalculationStep = step
                calculationProgress = Double(index) / Double(steps.count - 1)
            }
            
            // Simulate calculation time
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Add calculated positions progressively
            switch index {
            case 2: // Calculate planetary positions for birth date/time
                do {
                    // Combine birth date and time
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                    
                    var combinedComponents = DateComponents()
                    combinedComponents.year = dateComponents.year
                    combinedComponents.month = dateComponents.month
                    combinedComponents.day = dateComponents.day
                    combinedComponents.hour = timeComponents.hour
                    combinedComponents.minute = timeComponents.minute
                    combinedComponents.second = 0
                    combinedComponents.timeZone = TimeZone.current // Will be adjusted based on birth location
                    
                    guard let birthDateTime = calendar.date(from: combinedComponents) else {
                        throw NSError(domain: "ChartCalculation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date/time"])
                    }
                    
                    // Format date and time for the service
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    let birthDateStr = dateFormatter.string(from: birthDateTime)
                    let birthTimeStr = timeFormatter.string(from: birthDateTime)
                    
                    // Get positions using APIServices
                    let birthData = BirthData(
                        name: profileManager.profile.fullName,
                        date: birthDateStr,
                        time: birthTimeStr,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        city: selectedLocation,
                        state: nil,
                        country: "Unknown",
                        timezone: TimeZone.current.identifier
                    )
                    
                    let chartResponse = try await APIServices.shared.generateChart(
                        birthData: birthData,
                        systems: ["tropical"]
                    )
                    
                    // Convert chart positions to DetailedPlanetaryPosition format
                    var positions: [DetailedPlanetaryPosition] = []
                    
                    if let westernChart = chartResponse.westernChart {
                        for (planetName, position) in westernChart.positions {
                            let planetPosition = DetailedPlanetaryPosition(
                                id: planetName.lowercased(),
                                symbol: planetSymbol(for: planetName),
                                name: planetName,
                                sign: position.sign,
                                degree: position.degree,
                                retrograde: false, // TODO: Get retrograde status from API
                                house: position.house,
                                significance: planetSignificance(for: planetName)
                            )
                            positions.append(planetPosition)
                        }
                    }
                    
                    await MainActor.run {
                        for planetData in positions {
                            calculatedPositions[planetData.name] = planetData
                        }
                    }
                } catch {
                    await MainActor.run {
                        currentCalculationStep = "Error calculating planetary positions: \(error.localizedDescription)"
                    }
                }
            case 3: // Calculate house cusps and update planet houses
                await MainActor.run {
                    currentCalculationStep = "Calculating house positions..."
                }
            case 4: // Additional calculations or aspects
                await MainActor.run {
                    if !calculatedPositions.isEmpty {
                        currentCalculationStep = "Calculating planetary aspects..."
                        // Aspect calculations would go here
                    }
                }
            default:
                break
            }
        }
        
        await MainActor.run {
            isCalculating = false
            currentCalculationStep = "Calculation Complete!"
        }
    }
    
    private func saveToProfile() {
        var updatedProfile = profileManager.profile
        updatedProfile.birthDate = selectedDate
        updatedProfile.birthTime = selectedTime
        updatedProfile.birthPlace = selectedLocation
        if let coordinate = selectedCoordinate {
            updatedProfile.birthLatitude = coordinate.latitude
            updatedProfile.birthLongitude = coordinate.longitude
        }
        profileManager.updateProfile(updatedProfile)
    }
}

// MARK: - Step Views

struct BirthDateStepView: View {
    @Binding var selectedDate: Date
    @State private var animateCalendar = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateCalendar ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateCalendar)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                
                Text("Birth Date Foundation")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Your birth date determines the fundamental positions of all planets in your astrological chart. This is the starting point for all calculations.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                DatePicker("Birth Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    Text("Selected Date:")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 20)
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            animateCalendar = true
        }
    }
}

struct BirthTimeStepView: View {
    @Binding var selectedTime: Date
    @State private var animateClock = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.badge.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(animateClock ? 360 : 0))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: animateClock)
                }
                
                Text("Precise Timing")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Your exact birth time determines your rising sign and the positions of the astrological houses, which affect personality traits and life areas.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                DatePicker("Birth Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    Text("Selected Time:")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(selectedTime.formatted(date: .omitted, time: .shortened))
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 20)
                
                Text("💡 If you don't know your exact birth time, 12:00 PM is used as default")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            animateClock = true
        }
    }
}

struct LocationStepView: View {
    @Binding var searchText: String
    @Binding var locationResults: [LocationResult]
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var isSearching: Bool
    
    @State private var animateGlobe = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(animateGlobe ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: animateGlobe)
                }
                
                Text("Geographic Coordinates")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Your birth location establishes the coordinate system for calculating planetary positions as seen from your specific place on Earth.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Location Search - Using MapKitAutocompleteView like in onboarding
                VStack(spacing: 16) {
                    MapKitAutocompleteView(
                        selectedLocation: Binding(
                            get: { 
                                if !selectedLocation.isEmpty,
                                   let coordinate = selectedCoordinate {
                                    return LocationResult(
                                        fullName: selectedLocation,
                                        coordinate: coordinate,
                                        timezone: "UTC"
                                    )
                                }
                                return nil
                            },
                            set: { newLocation in
                                if let location = newLocation {
                                    selectedLocation = location.fullName
                                    selectedCoordinate = location.coordinate
                                } else {
                                    selectedLocation = ""
                                    selectedCoordinate = nil
                                }
                            }
                        ),
                        placeholder: "Search for your birth city..."
                    ) { location in
                        selectedLocation = location.fullName
                        selectedCoordinate = location.coordinate
                    }
                    
                    // Selected Location Display
                    if !selectedLocation.isEmpty {
                        VStack(spacing: 8) {
                            Text("Selected Location:")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(selectedLocation)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                            
                            if let coordinate = selectedCoordinate {
                                Text("Lat: \(coordinate.latitude, specifier: "%.2f"), Lon: \(coordinate.longitude, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            animateGlobe = true
        }
    }
}

struct CalculationStepView: View {
    @Binding var isCalculating: Bool
    @Binding var calculationProgress: Double
    @Binding var currentStep: String
    @Binding var calculatedPositions: [String: DetailedPlanetaryPosition]
    
    let birthDate: Date
    let birthTime: Date
    let coordinate: CLLocationCoordinate2D?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: calculationProgress)
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: calculationProgress)
                    
                    Image(systemName: isCalculating ? "gearshape.2.fill" : "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isCalculating ? 360 : 0))
                        .animation(isCalculating ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isCalculating)
                }
                
                Text(isCalculating ? "Computing Your Chart" : "Calculation Complete!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                if isCalculating {
                    VStack(spacing: 16) {
                        Text(currentStep)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text("\(Int(calculationProgress * 100))% Complete")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 40)
                } else {
                    Text("All planetary positions and astrological elements have been calculated based on your birth data.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Show calculated positions as they appear
                if !calculatedPositions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calculated Positions:")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        ForEach(Array(calculatedPositions.keys.sorted()), id: \.self) { planet in
                            if let position = calculatedPositions[planet] {
                                HStack {
                                    Image(systemName: planetIcon(for: planet))
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .frame(width: 24)
                                    
                                    Text(planet)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(position.degree))°")
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.1))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.5), value: calculatedPositions.count)
                }
            }
            .padding(.vertical, 40)
        }
    }
    
    private func planetIcon(for planet: String) -> String {
        switch planet {
        case "Sun": return "sun.max.fill"
        case "Moon": return "moon.fill"
        case "Mercury": return "circle.fill"
        case "Venus": return "heart.fill"
        case "Mars": return "flame.fill"
        case "Jupiter": return "j.circle.fill"
        case "Saturn": return "s.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct ResultsStepView: View {
    let positions: [String: DetailedPlanetaryPosition]
    let birthDate: Date
    let birthTime: Date
    let location: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Birth Data Summary
                VStack(spacing: 12) {
                    InfoRowView(title: "Birth Date", value: birthDate.formatted(date: .complete, time: .omitted))
                    InfoRowView(title: "Birth Time", value: birthTime.formatted(date: .omitted, time: .shortened))
                    InfoRowView(title: "Location", value: location)
                }
                .padding(.horizontal, 40)
                
                // Interactive Chart Visualization
                AstrologicalChartView(
                    positions: positions,
                    birthDate: birthDate,
                    birthTime: birthTime,
                    location: location
                )
                .frame(height: 400)
                .padding(.horizontal, 20)
                
                // Explanation
                VStack(spacing: 16) {
                    Text("Understanding Your Chart")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("This wheel represents the sky at your exact moment of birth. The outer ring shows the 12 zodiac signs, while the inner sections represent the 12 houses of life. Each planet's position reveals unique aspects of your personality and life path.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Tap on any planet to learn more about its influence.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .italic()
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
    }
}

struct InfoRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// Note: DetailedPlanetaryPosition is now defined in PlanetaryDataService.swift

// MARK: - Astrological Chart View

struct AstrologicalChartView: View {
    let positions: [String: DetailedPlanetaryPosition]
    let birthDate: Date
    let birthTime: Date
    let location: String
    
    @State private var selectedPlanet: String?
    @State private var showPlanetInfo = false
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false
    
    private let zodiacSigns = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
    private let zodiacNames = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", 
                               "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    private let houseNumbers = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1),
                    Color.indigo.opacity(0.2)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 200
            )
            .blur(radius: 20)
            
            // Main chart
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let outerRadius = min(geometry.size.width, geometry.size.height) / 2 - 20
                
                ZStack {
                    // Outer zodiac ring
                    ZodiacRing(
                        center: center,
                        radius: outerRadius,
                        zodiacSigns: zodiacSigns,
                        zodiacNames: zodiacNames,
                        rotationAngle: rotationAngle
                    )
                    
                    // House divisions
                    HouseDivisions(
                        center: center,
                        radius: outerRadius * 0.85,
                        houseNumbers: houseNumbers
                    )
                    
                    // Inner circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: outerRadius * 1.4, height: outerRadius * 1.4)
                        .position(center)
                    
                    // Planet positions
                    ForEach(Array(positions.keys), id: \.self) { planetName in
                        if let position = positions[planetName] {
                            PlanetMarker(
                                planet: planetName,
                                position: position,
                                center: center,
                                radius: outerRadius * 0.7,
                                isSelected: selectedPlanet == planetName,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedPlanet = planetName
                                        showPlanetInfo = true
                                    }
                                }
                            )
                        }
                    }
                    
                    // Center info
                    VStack(spacing: 4) {
                        Text("Birth Chart")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Text(birthDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text(birthTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .position(center)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                isAnimating = true
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showPlanetInfo) {
            if let planet = selectedPlanet, let position = positions[planet] {
                PlanetInfoSheet(planet: planet, position: position)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Zodiac Ring Component

struct ZodiacRing: View {
    let center: CGPoint
    let radius: CGFloat
    let zodiacSigns: [String]
    let zodiacNames: [String]
    let rotationAngle: Double
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
            
            // Zodiac divisions and signs
            ForEach(0..<12) { index in
                // Each zodiac sign spans 30 degrees
                // Starting from Aries at 0 degrees (Spring Equinox)
                let startAngle = Double(index) * 30.0
                let signAngle = startAngle + 15.0 // Center of each sign
                
                // Convert to drawing coordinates (subtract 90 to start from East)
                let drawAngle = startAngle - 90.0
                let drawSignAngle = signAngle - 90.0
                
                // Division lines
                Path { path in
                    path.move(to: center)
                    let endX = center.x + radius * cos(drawAngle * .pi / 180)
                    let endY = center.y + radius * sin(drawAngle * .pi / 180)
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                
                // Zodiac signs
                Text(zodiacSigns[index])
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .position(
                        x: center.x + (radius - 25) * cos(drawSignAngle * .pi / 180),
                        y: center.y + (radius - 25) * sin(drawSignAngle * .pi / 180)
                    )
                    .rotationEffect(.degrees(-rotationAngle))
            }
        }
        .rotationEffect(.degrees(rotationAngle))
    }
}

// MARK: - House Divisions Component

struct HouseDivisions: View {
    let center: CGPoint
    let radius: CGFloat
    let houseNumbers: [String]
    
    var body: some View {
        ZStack {
            // House circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
            
            // House divisions
            ForEach(0..<12) { index in
                // For equal houses, each house spans 30 degrees
                // In real implementation, this would use calculated house cusps
                let angle = Double(index) * 30.0 - 90.0
                let numberAngle = angle + 15.0
                
                // Division lines
                Path { path in
                    let startRadius = radius * 0.3
                    let startX = center.x + startRadius * cos(angle * .pi / 180)
                    let startY = center.y + startRadius * sin(angle * .pi / 180)
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    let endX = center.x + radius * cos(angle * .pi / 180)
                    let endY = center.y + radius * sin(angle * .pi / 180)
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                // House numbers
                Text(houseNumbers[index])
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .position(
                        x: center.x + (radius * 0.6) * cos(numberAngle * .pi / 180),
                        y: center.y + (radius * 0.6) * sin(numberAngle * .pi / 180)
                    )
            }
        }
    }
}

// MARK: - Planet Marker Component

struct PlanetMarker: View {
    let planet: String
    let position: DetailedPlanetaryPosition
    let center: CGPoint
    let radius: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    private var planetSymbol: String {
        switch planet {
        case "Sun": return "☉"
        case "Moon": return "☽"
        case "Mercury": return "☿"
        case "Venus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturn": return "♄"
        case "Uranus": return "♅"
        case "Neptune": return "♆"
        case "Pluto": return "♇"
        default: return "●"
        }
    }
    
    private var planetColor: Color {
        switch planet {
        case "Sun": return .yellow
        case "Moon": return .gray
        case "Mercury": return .orange
        case "Venus": return .pink
        case "Mars": return .red
        case "Jupiter": return .purple
        case "Saturn": return .brown
        case "Uranus": return .cyan
        case "Neptune": return .blue
        case "Pluto": return .indigo
        default: return .white
        }
    }
    
    var body: some View {
        // Ensure we're using the full ecliptic longitude (0-360 degrees)
        // Subtract 90 to start from the Ascendant (East) position
        let normalizedDegree = position.degree.truncatingRemainder(dividingBy: 360.0)
        let angle = (normalizedDegree < 0 ? normalizedDegree + 360.0 : normalizedDegree) - 90.0
        let angleRadians = angle * .pi / 180
        let x = center.x + radius * cos(angleRadians)
        let y = center.y + radius * sin(angleRadians)
        
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(planetColor.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(planetColor, lineWidth: 2)
                    )
                    .scaleEffect(isSelected ? 1.3 : 1.0)
                
                Text(planetSymbol)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .position(x: x, y: y)
        .shadow(color: planetColor.opacity(0.5), radius: isSelected ? 8 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Planet Info Sheet

struct PlanetInfoSheet: View {
    let planet: String
    let position: DetailedPlanetaryPosition
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text(planet)
                    .font(.title.weight(.bold))
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.medium))
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Planet info
            VStack(spacing: 20) {
                // Symbol and sign
                HStack(spacing: 20) {
                    Text(position.symbol)
                        .font(.system(size: 60))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        let degreeInSign = position.degree.truncatingRemainder(dividingBy: 30.0)
                        let degrees = Int(degreeInSign)
                        let minutes = Int((degreeInSign - Double(degrees)) * 60)
                        
                        Text("in \(position.sign)")
                            .font(.title2.weight(.semibold))
                        Text("\(degrees)° \(minutes)' \(position.sign)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Ecliptic: \(String(format: "%.2f", position.degree))°")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if position.retrograde {
                            Label("Retrograde", systemImage: "arrow.uturn.backward")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                // House position
                if let house = position.house {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("House \(house)")
                            .font(.title3.weight(.medium))
                    }
                }
                
                // Significance
                if let significance = position.significance {
                    Text(significance)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Additional interpretations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Influences:")
                        .font(.headline)
                    
                    Text(getPlanetInterpretation(planet: planet, sign: position.sign))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func getPlanetInterpretation(planet: String, sign: String) -> String {
        // Simplified interpretations - in a real app, these would be more detailed
        switch planet {
        case "Sun":
            return "Your \(sign) Sun represents your core identity, ego, and life purpose. It shows how you express yourself and seek recognition."
        case "Moon":
            return "Your \(sign) Moon reveals your emotional nature, instincts, and subconscious patterns. It shows what makes you feel secure."
        case "Mercury":
            return "Mercury in \(sign) shapes your communication style, thinking patterns, and how you process information."
        case "Venus":
            return "Venus in \(sign) influences your approach to love, relationships, beauty, and what brings you pleasure."
        case "Mars":
            return "Mars in \(sign) drives your ambition, energy, and how you assert yourself in pursuit of your desires."
        default:
            return "\(planet) in \(sign) brings unique energies and influences to your chart."
        }
    }
}

#Preview {
    PlanetaryCalculationsView()
        .environmentObject(UserProfileManager())
}
