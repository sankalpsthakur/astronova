import SwiftUI

// MARK: - Supporting Types

struct DetailedPlanetaryPosition: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let sign: String
    let degree: Double
    let retrograde: Bool
    let house: Int?
    let significance: String?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, name, sign, degree, retrograde, house, significance
    }
}

struct PlanetaryCalculationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var currentStep = 0
    @State private var animateElements = false
    
    private let totalSteps = 6
    private let freeSteps = 2 // Free users see steps 0 and 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic Background
                cosmicBackground
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Tutorial Content
                    TabView(selection: $currentStep) {
                        // Step 1: Birth Data Input (Free)
                        BirthDataExplanationView()
                            .tag(0)
                        
                        // Step 2: Coordinate Transformation (Free)
                        CoordinateVisualizationView()
                            .tag(1)
                        
                        // Steps 3-6: Pro Content
                        if auth.state == .signedIn {
                            SiderealTimeAnimationView()
                                .tag(2)
                            
                            PlanetaryCalculationView()
                                .environmentObject(auth)
                                .tag(3)
                            
                            HouseSystemInteractiveView()
                                .tag(4)
                            
                            AspectVisualizationView()
                                .tag(5)
                        } else {
                            // Pro Upsell for steps 3-6
                            ForEach(2..<totalSteps, id: \.self) { step in
                                ProUpsellView(stepTitle: stepTitle(for: step))
                                    .tag(step)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Navigation Controls
                    navigationControls
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 4) {
                        Text("How Your Chart is Calculated")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        Text("Step \(currentStep + 1) of \(totalSteps)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animateElements = true
            }
        }
    }
    
    // MARK: - Cosmic Background
    
    private var cosmicBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.25),
                    Color(red: 0.15, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated stars
            ForEach(0..<30, id: \.self) { _ in
                Circle()
                    .fill(.white.opacity(Double.random(in: 0.3...0.7)))
                    .frame(width: CGFloat.random(in: 1...2))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(animateElements ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateElements
                    )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🔮")
                    .font(.title)
                Text("Learn the Ancient Art")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            
            Text("Discover how astrologers have calculated birth charts for thousands of years")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        VStack(spacing: 16) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(progressColor(for: step))
                        .frame(width: 10, height: 10)
                        .scaleEffect(currentStep == step ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
            .padding(.vertical, 8)
            
            // Navigation Buttons
            HStack(spacing: 16) {
                // Previous Button
                if currentStep > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Next Button or Pro Upsell
                if currentStep < totalSteps - 1 {
                    if currentStep >= freeSteps && auth.state != .signedIn {
                        Button {
                            // TODO: Show paywall when subscription system is integrated
                        } label: {
                            HStack(spacing: 8) {
                                Text("Unlock Pro")
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                        }
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - Helper Methods
    
    private func progressColor(for step: Int) -> Color {
        if step < currentStep {
            return .green
        } else if step == currentStep {
            return .white
        } else if step >= freeSteps && auth.state != .signedIn {
            return .gray.opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func stepTitle(for step: Int) -> String {
        switch step {
        case 0: return "Birth Data Input"
        case 1: return "Coordinate Transformation"
        case 2: return "Sidereal Time"
        case 3: return "Planetary Positions"
        case 4: return "House System"
        case 5: return "Aspect Calculation"
        default: return "Unknown Step"
        }
    }
}

// MARK: - Individual Tutorial Steps

struct BirthDataExplanationView: View {
    @State private var animateData = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("1. Your Birth Data")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("The Foundation of Your Chart")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Interactive Birth Data Example
                VStack(spacing: 16) {
                    Text("Every birth chart begins with three essential pieces of information:")
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        birthDataRow(icon: "calendar", title: "Date of Birth", value: "March 21, 1990", description: "Determines planetary positions")
                        birthDataRow(icon: "clock", title: "Time of Birth", value: "2:30 PM", description: "Calculates house cusps & ascendant")
                        birthDataRow(icon: "location", title: "Place of Birth", value: "New York, NY", description: "Sets geographical coordinates")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Why It Matters
                VStack(spacing: 12) {
                    Text("Why Precision Matters")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("A difference of just 4 minutes in birth time can change your rising sign. Your exact coordinates affect house positions, making your reading uniquely yours.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateData = true
            }
        }
    }
    
    private func birthDataRow(icon: String, title: String, value: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.cyan)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .scaleEffect(animateData ? 1.0 : 0.9)
        .opacity(animateData ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.5).delay(Double.random(in: 0...0.3)), value: animateData)
    }
}

struct CoordinateVisualizationView: View {
    @State private var animateGlobe = false
    @State private var showCoordinates = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("2. Earth Coordinates")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Mapping Your Place in Space")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Globe Visualization
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(0.8), .blue.opacity(0.3)],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                        .rotationEffect(.degrees(animateGlobe ? 360 : 0))
                        .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateGlobe)
                    
                    // Coordinate Grid
                    VStack(spacing: 20) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(.white.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                    .frame(width: 180)
                    
                    HStack(spacing: 45) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 1, height: 180)
                        }
                    }
                    
                    // Your Location Marker
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(.red.opacity(0.3), lineWidth: 4)
                                .scaleEffect(showCoordinates ? 2 : 1)
                                .opacity(showCoordinates ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(), value: showCoordinates)
                        )
                        .offset(x: 30, y: -20)
                }
                
                // Coordinate Explanation
                VStack(spacing: 16) {
                    Text("Your birth location becomes your unique cosmic address:")
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        coordinateRow(label: "Latitude", value: "40.7128° N", description: "North-South position")
                        coordinateRow(label: "Longitude", value: "74.0060° W", description: "East-West position")
                    }
                }
                
                // Impact Explanation
                VStack(spacing: 12) {
                    Text("Why Location Matters")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("Your exact coordinates determine which planets were visible above the horizon at your birth, setting the foundation for your astrological houses and aspects.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .onAppear {
            animateGlobe = true
            withAnimation(.easeInOut(duration: 1).delay(0.5)) {
                showCoordinates = true
            }
        }
    }
    
    private func coordinateRow(label: String, value: String, description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SiderealTimeAnimationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("3. Sidereal Time")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Coming Soon - Pro Feature")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
        }
    }
}

struct PlanetaryCalculationView: View {
    @State private var currentStep = 0
    @State private var animateCalculation = false
    @State private var showDetails = false
    @State private var userCalculations: UserCalculationData?
    @State private var isLoading = false
    
    @EnvironmentObject private var auth: AuthState
    
    // Note: PlanetaryDataService access moved to methods to avoid build issues
    // private var planetaryService: PlanetaryDataService {
    //     return PlanetaryDataService.shared
    // }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("4. Planetary Positions")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Step-by-Step Calculation Walkthrough")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                if isLoading {
                    loadingView
                } else if let calculations = userCalculations {
                    userDataHeader(calculations: calculations)
                } else if auth.profileManager.isProfileComplete {
                    Text("Tap 'Calculate' to see your personalized calculations")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    exampleDataHeader
                }
                
                // Calculation Steps
                calculationStepsView
                
                // Data Tables
                if showDetails {
                    dataTablesView
                }
                
                // Action Buttons
                actionButtonsView
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateCalculation = true
            }
            
            // Auto-calculate if user profile is complete
            if auth.profileManager.isProfileComplete && userCalculations == nil {
                Task {
                    await calculateUserData()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.cyan)
            
            Text("Calculating your planetary positions...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func userDataHeader(calculations: UserCalculationData) -> some View {
        VStack(spacing: 12) {
            Text("Your Personal Calculation")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.cyan)
            
            VStack(spacing: 4) {
                Text("\(calculations.formattedBirthDate), \(calculations.formattedBirthTime)")
                Text("\(calculations.birthPlace)")
                Text("(\(String(format: "%.2f", calculations.latitude))°N, \(String(format: "%.2f", calculations.longitude))°E)")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var exampleDataHeader: some View {
        VStack(spacing: 12) {
            Text("Educational Example")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.orange)
            
            VStack(spacing: 4) {
                Text("24 Dec 1999, 07:00 IST (+05:30)")
                Text("Guna, Madhya Pradesh")
                Text("(24.65°N, 77.32°E)")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.8))
            
            Text("Complete your profile to see your own birth chart calculations")
                .font(.caption)
                .foregroundStyle(.orange.opacity(0.9))
                .italic()
        }
        .padding()
        .background(.orange.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var calculationStepsView: some View {
        VStack(spacing: 16) {
            if let calculations = userCalculations {
                calculationStepCard(
                    step: "0",
                    title: "Convert Local Time → UTC",
                    content: "\(calculations.formattedBirthTime) \(calculations.timezone) → UTC",
                    result: calculations.utcTime
                )
                
                calculationStepCard(
                    step: "1",
                    title: "Compute Julian Date",
                    content: "JD = 367×Y - 7×(Y+(M+9)÷12)÷4 + 275×M÷9 + D + 1721013.5 + UT÷24",
                    result: String(format: "%.4f", calculations.julianDate)
                )
                
                calculationStepCard(
                    step: "2",
                    title: "Pull Planetary Longitudes (Tropical)",
                    content: "From ephemeris for \(calculations.formattedBirthDate) 00 UT",
                    result: "See tropical table below"
                )
                
                calculationStepCard(
                    step: "3",
                    title: "Subtract Lahiri Ayanamsa",
                    content: "Ayanamsa ≈ \(String(format: "%.1f", calculations.ayanamsa))° (\(calculations.birthYear) value)\nSubtract from all planetary positions",
                    result: "Sidereal positions"
                )
                
                calculationStepCard(
                    step: "4",
                    title: "Map to 12 Signs",
                    content: "0-360° result into 12 × 30° signs\nSign = floor(longitude ÷ 30°)",
                    result: "Final chart positions"
                )
            } else {
                // Example steps with educational data
                calculationStepCard(
                    step: "0",
                    title: "Convert Local Time → UTC",
                    content: "Educational Example:\n07:00 IST (+05:30) → UTC\n07:00 - 05:30 = 01:30 UTC",
                    result: "01:30 UTC"
                )
                
                calculationStepCard(
                    step: "1",
                    title: "Compute Julian Date",
                    content: "Educational Example:\nConvert birth date + time to astronomical timestamp:\nJD = 367×Y - 7×(Y+(M+9)÷12)÷4 + 275×M÷9 + D + 1721013.5 + UT÷24\nY=1999, M=12, D=24, UT=1.5625 hours",
                    result: "2451536.5625"
                )
                
                calculationStepCard(
                    step: "2",
                    title: "Pull Planetary Longitudes (Tropical)",
                    content: "Educational Example:\nUse ephemeris data for planetary positions at exact moment:\nSource: 24 Dec 1999 00:00 UT\nInterpolate to 01:30 UT if needed",
                    result: "See table below"
                )
                
                calculationStepCard(
                    step: "3",
                    title: "Subtract Lahiri Ayanamsa",
                    content: "Educational Example:\nConvert from tropical to sidereal zodiac:\nAyanamsa ≈ 23°51′ (1999 value)\nSubtract from all planetary longitudes\nAccounts for Earth's precession over time",
                    result: "Sidereal positions"
                )
                
                calculationStepCard(
                    step: "4",
                    title: "Map to 12 Signs",
                    content: "Educational Example:\nConvert degrees to zodiac signs:\n0-360° mapped into 12 × 30° segments\nSign = floor(longitude ÷ 30°)\nDegree within sign = longitude mod 30°",
                    result: "Final chart positions"
                )
            }
        }
    }
    
    private var dataTablesView: some View {
        VStack(spacing: 16) {
            if let calculations = userCalculations {
                userTropicalDataTable(calculations: calculations)
                userSiderealDataTable(calculations: calculations)
            } else {
                exampleTropicalDataTable
                exampleSiderealDataTable
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Toggle Details Button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    Text(showDetails ? "Hide Data Tables" : "Show Calculation Data")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            // Calculate Button (if user profile complete but no calculations)
            if auth.profileManager.isProfileComplete && userCalculations == nil && !isLoading {
                Button {
                    Task {
                        await calculateUserData()
                    }
                } label: {
                    HStack {
                        Image(systemName: "function")
                        Text("Calculate My Chart")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
                    .background(.cyan)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateUserData() async {
        isLoading = true
        
        let profile = auth.profileManager.profile
        guard let birthTime = profile.birthTime,
              let _ = profile.birthCoordinates,
              let _ = profile.timezone,
              let _ = profile.birthPlace else {
            isLoading = false
            return
        }
        
        // Format dates for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        _ = dateFormatter.string(from: profile.birthDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        _ = timeFormatter.string(from: birthTime)
        
        // Get planetary positions from API
        // Note: Temporarily disabled - requires proper PlanetaryDataService integration
        // let positions = try await PlanetaryDataService.shared.getBirthChartPositions(
        //     birthDate: birthDateString,
        //     birthTime: birthTimeString,
        //     latitude: coordinates.latitude,
        //     longitude: coordinates.longitude,
        //     timezone: timezone
        // )
        let positions: [DetailedPlanetaryPosition] = [] // Placeholder
        
        // Create calculation data
        await MainActor.run {
            userCalculations = UserCalculationData(
                profile: profile,
                planetaryPositions: positions
            )
            isLoading = false
        }
    }
    
    private func calculationStepCard(step: String, title: String, content: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Step \(step)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.cyan)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)
            
            HStack {
                Text("Result:")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(result)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.cyan)
            }
        }
        .padding()
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(animateCalculation ? 1.0 : 0.95)
        .opacity(animateCalculation ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.5).delay(Double(step) ?? 0 * 0.1), value: animateCalculation)
    }
    
    private func userTropicalDataTable(calculations: UserCalculationData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tropical Longitudes (Your Chart)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            VStack(spacing: 8) {
                ForEach(calculations.planetaryPositions, id: \.id) { position in
                    HStack {
                        Text(position.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(String(format: "%.1f°", position.degree))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(position.sign)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        if position.retrograde {
                            Text("R")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func userSiderealDataTable(calculations: UserCalculationData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sidereal Conversion (−\(String(format: "%.1f", calculations.ayanamsa))°)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            VStack(spacing: 8) {
                ForEach(calculations.siderealPositions, id: \.planet) { data in
                    HStack {
                        Text(data.planet)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(String(format: "%.1f°", data.siderealDegree))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.green)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(data.siderealSign)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var exampleTropicalDataTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tropical Longitudes (Educational Example)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                ForEach(SankalpExample.tropicalData, id: \.planet) { data in
                    HStack {
                        Text(data.planet)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(data.longitude)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(data.sign)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var exampleSiderealDataTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sidereal Conversion (Educational Example - −23°51′)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                ForEach(SankalpExample.siderealData, id: \.planet) { data in
                    HStack {
                        Text(data.planet)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(data.longitude)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.green)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(data.signPosition)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Data Models

struct UserCalculationData {
    let profile: UserProfile
    let planetaryPositions: [DetailedPlanetaryPosition]
    let julianDate: Double
    let ayanamsa: Double
    let siderealPositions: [SiderealPlanetData]
    
    init(profile: UserProfile, planetaryPositions: [DetailedPlanetaryPosition]) {
        self.profile = profile
        self.planetaryPositions = planetaryPositions
        self.julianDate = Self.calculateJulianDate(from: profile)
        self.ayanamsa = Self.calculateAyanamsa(for: profile.birthDate)
        self.siderealPositions = Self.calculateSiderealPositions(
            from: planetaryPositions,
            ayanamsa: ayanamsa
        )
    }
    
    var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: profile.birthDate)
    }
    
    var formattedBirthTime: String {
        guard let birthTime = profile.birthTime else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: birthTime)
    }
    
    var birthPlace: String {
        profile.birthPlace ?? "Unknown Location"
    }
    
    var latitude: Double {
        profile.birthCoordinates?.latitude ?? 0.0
    }
    
    var longitude: Double {
        profile.birthCoordinates?.longitude ?? 0.0
    }
    
    var timezone: String {
        profile.timezone ?? "UTC"
    }
    
    var utcTime: String {
        guard let birthTime = profile.birthTime else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: birthTime)
    }
    
    var birthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: profile.birthDate)
    }
    
    private static func calculateJulianDate(from profile: UserProfile) -> Double {
        guard let birthTime = profile.birthTime else { return 0.0 }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: profile.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
        
        let year = dateComponents.year ?? 2000
        let month = dateComponents.month ?? 1
        let day = dateComponents.day ?? 1
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0
        
        // Julian Date calculation
        let a = (14 - month) / 12
        let y = year - a
        let m = month + 12 * a - 3
        
        let jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 + 1721119
        let fractionalDay = (Double(hour) + Double(minute) / 60.0) / 24.0
        
        return Double(jdn) + fractionalDay
    }
    
    private static func calculateAyanamsa(for date: Date) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        // Simplified Lahiri ayanamsa calculation (approximate)
        let baseYear = 1900.0
        let baseAyanamsa = 22.46  // Ayanamsa in 1900
        let rate = 0.0139  // Rate per year (approximately 50.3" per year)
        
        return baseAyanamsa + (Double(year) - baseYear) * rate
    }
    
    private static func calculateSiderealPositions(
        from positions: [DetailedPlanetaryPosition],
        ayanamsa: Double
    ) -> [SiderealPlanetData] {
        return positions.map { position in
            let siderealDegree = position.degree - ayanamsa
            let normalizedDegree = siderealDegree < 0 ? siderealDegree + 360 : siderealDegree
            let siderealSign = signFromDegree(normalizedDegree)
            
            return SiderealPlanetData(
                planet: position.name,
                siderealDegree: normalizedDegree,
                siderealSign: siderealSign
            )
        }
    }
    
    private static func signFromDegree(_ degree: Double) -> String {
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let signIndex = Int(degree / 30.0) % 12
        return signs[signIndex]
    }
}

struct SiderealPlanetData {
    let planet: String
    let siderealDegree: Double
    let siderealSign: String
}

struct SankalpExample {
    struct PlanetaryData {
        let planet: String
        let longitude: String
        let sign: String
        let signPosition: String
    }
    
    static let tropicalData = [
        PlanetaryData(planet: "Sun", longitude: "01°42′", sign: "Capricorn", signPosition: "07°51′ Sag"),
        PlanetaryData(planet: "Moon", longitude: "19°42′", sign: "Cancer", signPosition: "25°51′ Gem"),
        PlanetaryData(planet: "Mercury", longitude: "18°50′", sign: "Sagittarius", signPosition: "24°59′ Sco"),
        PlanetaryData(planet: "Venus", longitude: "21°20′", sign: "Scorpio", signPosition: "27°29′ Lib"),
        PlanetaryData(planet: "Mars", longitude: "21°22′", sign: "Aquarius", signPosition: "27°31′ Cap"),
        PlanetaryData(planet: "Jupiter", longitude: "25°01′", sign: "Aries", signPosition: "01°10′ Ari"),
        PlanetaryData(planet: "Saturn", longitude: "10°37′", sign: "Taurus", signPosition: "16°46′ Ari")
    ]
    
    static let siderealData = [
        PlanetaryData(planet: "Sun", longitude: "247°51′", sign: "", signPosition: "07°51′ Sag"),
        PlanetaryData(planet: "Moon", longitude: "085°51′", sign: "", signPosition: "25°51′ Gem"),
        PlanetaryData(planet: "Mercury", longitude: "234°59′", sign: "", signPosition: "24°59′ Sco"),
        PlanetaryData(planet: "Venus", longitude: "207°29′", sign: "", signPosition: "27°29′ Lib"),
        PlanetaryData(planet: "Mars", longitude: "297°31′", sign: "", signPosition: "27°31′ Cap"),
        PlanetaryData(planet: "Jupiter", longitude: "001°10′", sign: "", signPosition: "01°10′ Ari"),
        PlanetaryData(planet: "Saturn", longitude: "016°46′", sign: "", signPosition: "16°46′ Ari")
    ]
}

struct HouseSystemInteractiveView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("5. House System")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Coming Soon - Pro Feature")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
        }
    }
}

struct AspectVisualizationView: View {
    @State private var animateInterpretation = false
    @State private var currentInterpretation = 0
    @State private var showChart = false
    @State private var selectedPlanet: String?
    @State private var userCalculations: UserCalculationData? = nil
    
    private let interpretations = [
        InterpretationData(
            placement: "Sun 7° Sagittarius",
            meaning: "Focus on expansion, study, outreach",
            description: "Your core identity is driven by a quest for knowledge and truth. You naturally seek to broaden horizons through learning, teaching, and exploring new philosophies."
        ),
        InterpretationData(
            placement: "Moon 25° Gemini",
            meaning: "Agile emotions, need for varied input",
            description: "Your emotional nature thrives on mental stimulation and variety. You process feelings through communication and benefit from diverse perspectives."
        ),
        InterpretationData(
            placement: "Mars 27° Capricorn",
            meaning: "Action organized toward clear goals",
            description: "Your drive and ambition are channeled through structured, disciplined approaches. You achieve through persistent, methodical effort toward long-term objectives."
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("5. Chart Construction & Interpretation")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Visual Chart & Personal Insights")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Process Overview
                VStack(spacing: 16) {
                    Text("A 12-slice wheel displays your cosmic blueprint")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.cyan)
                    
                    Text("Each planet icon is placed at its exact sidereal position. Tap planets to highlight their interpretations below.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Visual Chart Section
                VStack(spacing: 16) {
                    if userCalculations != nil {
                        Text("Your Sidereal Chart Wheel")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.cyan)
                    } else {
                        Text("Example Sidereal Chart Wheel")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    
                    chartWheelView
                }
                .padding()
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Interactive Interpretation Cards
                VStack(spacing: 16) {
                    ForEach(Array(interpretations.enumerated()), id: \.offset) { index, interpretation in
                        interpretationCard(interpretation: interpretation, index: index)
                    }
                }
                
                // Process Flow
                VStack(spacing: 16) {
                    Text("The Translation Process")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 12) {
                        processStep(number: "1", title: "Position Analysis", description: "Planet + Sign + Degree")
                        processStep(number: "2", title: "Archetypal Meaning", description: "Ancient symbolic associations")
                        processStep(number: "3", title: "Modern Context", description: "Contemporary life applications")
                        processStep(number: "4", title: "Personal Synthesis", description: "Unified interpretation")
                    }
                }
                .padding()
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Tutorial Cards Section
                VStack(spacing: 12) {
                    Text("Complete Tutorial Cards")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 8) {
                        tutorialCard(
                            number: "1",
                            visual: "📅 ▶️ JD",
                            caption: "We convert your time & place into an astronomical timestamp."
                        )
                        tutorialCard(
                            number: "2", 
                            visual: "🌌",
                            caption: "Ephemeris gives actual planet angles at that moment."
                        )
                        tutorialCard(
                            number: "3",
                            visual: "🔄 24° ➡️",
                            caption: "Subtract ayanamsa to shift from tropical to sidereal."
                        )
                        tutorialCard(
                            number: "4",
                            visual: "⭕️",
                            caption: "Here is your sidereal chart wheel."
                        )
                        tutorialCard(
                            number: "5",
                            visual: "📖",
                            caption: "Each placement translates into personal insight."
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Learn More Section
                VStack(spacing: 12) {
                    Text("Learn More Resources")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 8) {
                        learnMoreLink(title: "NASA Horizons", subtitle: "Raw astronomical data source")
                        learnMoreLink(title: "Lahiri Ayanamsa", subtitle: "Government standard for precession")
                        learnMoreLink(title: "Traditional Sources", subtitle: "Classical astrological wisdom")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateInterpretation = true
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.8)) {
                showChart = true
            }
        }
    }
    
    private var chartWheelView: some View {
        VStack {
            Text("Chart Wheel Coming Soon")
                .foregroundStyle(.white)
        }
        /*
        ZStack {
            // Outer circle (chart boundary)
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 2)
                .frame(width: 280, height: 280)
            
            // Inner circle
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)
            
            // 12 house divisions
            ForEach(0..<12, id: \.self) { house in
                Path { path in
                    let center = CGPoint(x: 140, y: 140)
                    let angle = Double(house) * 30.0 * .pi / 180.0
                    path.move(to: center)
                    path.addLine(to: CGPoint(
                        x: center.x + 140 * cos(angle - .pi / 2),
                        y: center.y + 140 * sin(angle - .pi / 2)
                    ))
                }
                .stroke(.white.opacity(0.2), lineWidth: 1)
            }
            
            // Zodiac signs around the wheel
            ForEach(0..<12, id: \.self) { signIndex in
                let signs = ["♈︎", "♉︎", "♊︎", "♋︎", "♌︎", "♍︎", "♎︎", "♏︎", "♐︎", "♑︎", "♒︎", "♓︎"]
                let angle = Double(signIndex) * 30.0 * .pi / 180.0 + (.pi / 12)
                
                Text(signs[signIndex])
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                    .position(
                        x: 140 + 120 * cos(angle - .pi / 2),
                        y: 140 + 120 * sin(angle - .pi / 2)
                    )
            }
            
            // Planet positions (example positions)
            let planetData = [
                ("☉", 7.85, "Sun"), // Sun in Sagittarius 7°
                ("☽", 85.85, "Moon"), // Moon in Gemini 25°
                ("♂", 297.5, "Mars") // Mars in Capricorn 27°
            ]
            
            ForEach(Array(planetData.enumerated()), id: \.offset) { index, planet in
                let (symbol, degrees, name) = planet
                let angle = degrees * .pi / 180.0
                
                Button {
                    selectedPlanet = selectedPlanet == name ? nil : name
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedPlanet == name ? .cyan : .white)
                            .frame(width: 24, height: 24)
                        
                        Text(symbol)
                            .font(.system(size: 14))
                            .foregroundStyle(selectedPlanet == name ? .black : .black)
                    }
                }
                .position(
                    x: 140 + 80 * cos(angle - .pi / 2),
                    y: 140 + 80 * sin(angle - .pi / 2)
                )
                .scaleEffect(showChart ? 1.0 : 0.1)
                .opacity(showChart ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.2), value: showChart)
            }
            
            // Center point
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 4, height: 4)
        }
        .frame(width: 280, height: 280)
        
        if let selected = selectedPlanet {
            Text("Selected: \(selected)")
                .font(.caption)
                .foregroundStyle(.cyan)
                .padding(.top, 8)
        } else {
            Text("Tap planets above to explore their meanings")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)
        }
        */
    }
    
    private func interpretationCard(interpretation: InterpretationData, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(interpretation.placement)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.cyan)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Text(interpretation.meaning)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.3))
                .clipShape(Capsule())
            
            Text(interpretation.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(animateInterpretation ? 1.0 : 0.95)
        .opacity(animateInterpretation ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.2), value: animateInterpretation)
    }
    
    private func processStep(number: String, title: String, description: String) -> some View {
        numberedRow(
            number: number,
            content: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        )
    }
    
    private func tutorialCard(number: String, visual: String, caption: String) -> some View {
        numberedRow(
            number: number,
            content: {
                HStack(spacing: 12) {
                    // Visual element
                    Text(visual)
                        .font(.body)
                        .frame(width: 60, alignment: .leading)
                    
                    // Caption
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                }
            }
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func numberedRow<Content: View>(
        number: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(.cyan)
                .clipShape(Circle())
            
            content()
            
            Spacer()
        }
    }
    
    private func learnMoreLink(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.cyan)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundStyle(.cyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct InterpretationData {
    let placement: String
    let meaning: String
    let description: String
}

struct ProUpsellView: View {
    let stepTitle: String
    @EnvironmentObject private var auth: AuthState
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.gray)
                
                Text(stepTitle)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Unlock Advanced Tutorials")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            VStack(spacing: 12) {
                Text("Upgrade to Pro to access:")
                    .font(.body)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    proFeatureRow("Complete 6-step tutorial")
                    proFeatureRow("Interactive planetary calculations")
                    proFeatureRow("House system comparisons")
                    proFeatureRow("Aspect visualization tools")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button {
                // TODO: Show paywall when subscription system is integrated
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Upgrade to Pro")
                    Image(systemName: "arrow.right")
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func proFeatureRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

#Preview {
    PlanetaryCalculationsView()
        .environmentObject(AuthState())
}
