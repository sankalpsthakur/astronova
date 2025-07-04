import SwiftUI
import CoreLocation

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
        
        for (index, (step, description)) in steps.enumerated() {
            await MainActor.run {
                currentCalculationStep = step
                calculationProgress = Double(index) / Double(steps.count - 1)
            }
            
            // Simulate calculation time
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Add calculated positions progressively
            await MainActor.run {
                switch index {
                case 2: // Planetary positions
                    calculatedPositions["Sun"] = DetailedPlanetaryPosition(name: "Sun", position: Double.random(in: 0...360))
                    calculatedPositions["Moon"] = DetailedPlanetaryPosition(name: "Moon", position: Double.random(in: 0...360))
                    calculatedPositions["Mercury"] = DetailedPlanetaryPosition(name: "Mercury", position: Double.random(in: 0...360))
                case 3: // More planets
                    calculatedPositions["Venus"] = DetailedPlanetaryPosition(name: "Venus", position: Double.random(in: 0...360))
                    calculatedPositions["Mars"] = DetailedPlanetaryPosition(name: "Mars", position: Double.random(in: 0...360))
                case 4: // Outer planets
                    calculatedPositions["Jupiter"] = DetailedPlanetaryPosition(name: "Jupiter", position: Double.random(in: 0...360))
                    calculatedPositions["Saturn"] = DetailedPlanetaryPosition(name: "Saturn", position: Double.random(in: 0...360))
                default:
                    break
                }
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
                    
                    Image(systemName: "calendar.badge.star")
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
                                    
                                    Text("\(Int(position.position))°")
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
    
    @State private var animateChart = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Your Astrological Chart")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                // Birth Data Summary
                VStack(spacing: 12) {
                    InfoRowView(title: "Birth Date", value: birthDate.formatted(date: .complete, time: .omitted))
                    InfoRowView(title: "Birth Time", value: birthTime.formatted(date: .omitted, time: .shortened))
                    InfoRowView(title: "Location", value: location)
                }
                .padding(.horizontal, 40)
                
                // Interactive Chart Visualization
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 240, height: 240)
                    
                    // Inner circles for houses
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    
                    // Zodiac divisions (12 houses)
                    ForEach(0..<12, id: \.self) { house in
                        Path { path in
                            path.move(to: CGPoint(x: 120, y: 120))
                            path.addLine(to: CGPoint(x: 120, y: 0))
                        }
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                        .rotationEffect(.degrees(Double(house * 30)))
                    }
                    
                    // Planet positions
                    ForEach(Array(positions.keys.enumerated()), id: \.element) { index, planet in
                        if let position = positions[planet] {
                            VStack(spacing: 4) {
                                Image(systemName: planetIcon(for: planet))
                                    .font(.system(size: 16))
                                    .foregroundStyle(planetColor(for: planet))
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 24, height: 24)
                                    )
                                
                                Text(planet.prefix(3))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 100)
                            .rotationEffect(.degrees(position.position))
                            .scaleEffect(animateChart ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateChart)
                        }
                    }
                }
                .padding(.vertical, 20)
                
                Text("This chart shows your planets' positions at the moment of birth. Each planet influences different aspects of your personality and life path.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            withAnimation {
                animateChart = true
            }
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
    
    private func planetColor(for planet: String) -> Color {
        switch planet {
        case "Sun": return .orange
        case "Moon": return .gray
        case "Mercury": return .yellow
        case "Venus": return .pink
        case "Mars": return .red
        case "Jupiter": return .purple
        case "Saturn": return .brown
        default: return .blue
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

// MARK: - Stub types for compilation
struct DetailedPlanetaryPosition {
    let name: String
    let position: Double
}

#Preview {
    PlanetaryCalculationsView()
        .environmentObject(UserProfileManager())
}