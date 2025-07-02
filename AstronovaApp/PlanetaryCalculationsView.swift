import SwiftUI
import UIKit
import Foundation

struct PlanetaryCalculationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var currentStep = 0
    @State private var animateElements = false
    @State private var showProUpgradeAlert = false
    
    private let totalSteps = 5
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
                        
                        // Steps 3-5: Pro Content
                        if auth.state == .signedIn {
                            SiderealTimeAnimationView()
                                .tag(2)
                            
                            CombinedCalculationView()
                                .environmentObject(auth)
                                .tag(3)
                            
                            AspectVisualizationView()
                                .tag(4)
                        } else {
                            // Pro Upsell for steps 3-5
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
                        Text("How It Works")
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
        .alert("Upgrade to Pro", isPresented: $showProUpgradeAlert) {
            Button("OK") { }
        } message: {
            Text("Unlock all planetary calculations and interpretations with Astronova Pro.")
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
                Text("⭐")
                    .font(.title)
                Text("Behind Your Chart")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            
            Text("From birth data to cosmic insights in 6 interactive steps")
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
                            showProUpgradeAlert = true
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
        case 0: return "Birth Data"
        case 1: return "Location"
        case 2: return "Sidereal Time"
        case 3: return "Chart Calculation"
        case 4: return "Your Chart"
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
                    Text("1. Birth Data")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Your Cosmic Coordinates")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Interactive Birth Data Example
                VStack(spacing: 12) {
                    VStack(spacing: 12) {
                        birthDataRow(icon: "calendar", title: "Date", value: "Mar 21, 1990", description: "Planetary positions")
                        birthDataRow(icon: "clock", title: "Time", value: "2:30 PM", description: "House cusps")
                        birthDataRow(icon: "location", title: "Place", value: "New York, NY", description: "Sky view angle")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Key Insight - Condensed
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("4 minutes = different rising sign")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(.orange.opacity(0.2))
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
                    Text("2. Location")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Your View of the Sky")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Simplified Globe Visualization
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(0.8), .blue.opacity(0.3)],
                                center: .center,
                                startRadius: 50,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                        .rotationEffect(.degrees(animateGlobe ? 360 : 0))
                        .animation(.linear(duration: 15).repeatForever(autoreverses: false), value: animateGlobe)
                    
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
                        .offset(x: 25, y: -15)
                }
                
                // Coordinate Display - Simplified
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("40.7°N")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.cyan)
                        Text("Latitude")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 4) {
                        Text("74.0°W")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.cyan)
                        Text("Longitude")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Key Insight - Condensed
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.blue)
                        Text("Sets which planets are visible above horizon")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(.blue.opacity(0.2))
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
    @State private var animateClock = false
    @State private var showCalculation = false
    @State private var currentStep = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("3. Sidereal Time")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Star Time vs. Solar Time")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Visual Clock Comparison
                HStack(spacing: 32) {
                    // Solar Clock
                    VStack(spacing: 12) {
                        Text("Solar Day")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.orange)
                        
                        clockView(color: .orange, rotation: animateClock ? 360 : 0)
                        
                        Text("24h 00m 00s")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    
                    // Sidereal Clock
                    VStack(spacing: 12) {
                        Text("Sidereal Day")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.cyan)
                        
                        clockView(color: .cyan, rotation: animateClock ? 366 : 0)
                        
                        Text("23h 56m 04s")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.cyan)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Key Concept
                VStack(spacing: 12) {
                    Text("Why Sidereal Time Matters")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("A sidereal day (23h 56m 04s) is Earth's rotation relative to distant stars. It's 4 minutes shorter than a solar day because Earth orbits the Sun.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Calculation Steps
                if showCalculation {
                    VStack(spacing: 16) {
                        Text("Sidereal Time Calculation")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.cyan)
                        
                        calculationStep(
                            step: "1",
                            title: "Greenwich Mean Sidereal Time (GMST)",
                            formula: "GMST = 6.697374558 + 0.06570982441908 × D + 1.00273790935 × T",
                            explanation: "Where D = days since J2000.0, T = time in hours"
                        )
                        
                        calculationStep(
                            step: "2",
                            title: "Local Sidereal Time (LST)",
                            formula: "LST = GMST + (Longitude ÷ 15)",
                            explanation: "Add longitude correction for your location"
                        )
                        
                        calculationStep(
                            step: "3",
                            title: "House Cusp Calculation",
                            formula: "Ascendant = arctan(sin(LST) ÷ (cos(ε) × cos(LST)))",
                            explanation: "LST determines rising sign and house positions"
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Interactive Examples
                VStack(spacing: 16) {
                    Text("Real-World Impact")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    impactExample(
                        icon: "sunrise",
                        title: "Rising Sign",
                        description: "Determines which sign appears on eastern horizon"
                    )
                    
                    impactExample(
                        icon: "house",
                        title: "House Cusps",
                        description: "Sets the 12 life areas in your birth chart"
                    )
                    
                    impactExample(
                        icon: "clock.arrow.2.circlepath",
                        title: "Timing Precision",
                        description: "4 minutes = different rising sign entirely"
                    )
                }
                
                // Show Calculation Button
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCalculation.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showCalculation ? "chevron.up" : "chevron.down")
                        Text(showCalculation ? "Hide Math" : "Show the Math")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animateClock = true
            }
        }
    }
    
    private func clockView(color: Color, rotation: Double) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: 80, height: 80)
            
            // Clock hands
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 25)
                .offset(y: -12.5)
                .rotationEffect(.degrees(rotation))
            
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
        }
    }
    
    private func calculationStep(step: String, title: String, formula: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text(formula)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.cyan)
                .padding(8)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func impactExample(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.cyan)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CombinedCalculationView: View {
    @State private var selectedTab = 0
    @State private var animateCalculation = false
    @State private var showDetails = false
    @State private var userCalculations: UserCalculationData?
    @State private var isLoading = false
    @State private var selectedSystem: HouseSystem = .placidus
    
    @EnvironmentObject private var auth: AuthState
    
    enum HouseSystem: String, CaseIterable {
        case placidus = "Placidus"
        case wholeSigns = "Whole Signs"
        case equal = "Equal House"
        
        var description: String {
            switch self {
            case .placidus: return "Most popular system"
            case .wholeSigns: return "Each house = one sign"
            case .equal: return "All houses exactly 30°"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("4. Chart Calculation")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Planets + Houses = Your Chart")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Tab Selector
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text("Planets")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selectedTab == 0 ? .black : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == 0 ? .cyan : .clear)
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 1
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text("Houses")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selectedTab == 1 ? .black : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == 1 ? .cyan : .clear)
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Content based on selected tab
                if selectedTab == 0 {
                    planetaryContent
                } else {
                    houseSystemContent
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateCalculation = true
            }
        }
    }
    
    private var planetaryContent: some View {
        VStack(spacing: 16) {
            // Quick Steps
            VStack(spacing: 12) {
                Text("Planetary Position Calculation")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.cyan)
                
                quickStep(number: "1", title: "Get UTC Time", icon: "clock")
                quickStep(number: "2", title: "Calculate Julian Date", icon: "calendar")
                quickStep(number: "3", title: "Get Tropical Positions", icon: "globe")
                quickStep(number: "4", title: "Apply Ayanamsa (-24°)", icon: "arrow.clockwise")
                quickStep(number: "5", title: "Map to Signs", icon: "star.circle")
            }
            
            // Sample Result
            VStack(spacing: 12) {
                Text("Sample Results")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                VStack(spacing: 8) {
                    planetRow(symbol: "☉", name: "Sun", position: "7° Sagittarius")
                    planetRow(symbol: "☽", name: "Moon", position: "25° Gemini")
                    planetRow(symbol: "♂", name: "Mars", position: "27° Capricorn")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var houseSystemContent: some View {
        VStack(spacing: 16) {
            systemSelector
            housesGrid
            keyDifferenceNote
        }
    }
    
    private var systemSelector: some View {
        HStack(spacing: 12) {
            ForEach(HouseSystem.allCases, id: \.self) { system in
                systemSelectorButton(for: system)
            }
        }
    }
    
    @ViewBuilder
    private func systemSelectorButton(for system: HouseSystem) -> some View {
        Button {
            selectedSystem = system
        } label: {
            VStack(spacing: 4) {
                let textColor = selectedSystem == system ? Color.black : Color.white
                let secondaryTextColor = selectedSystem == system ? Color.black.opacity(0.7) : Color.white.opacity(0.6)
                
                Text(system.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(textColor)
                Text(system.description)
                    .font(.caption2)
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(8)
            .background {
                if selectedSystem == system {
                    Color.cyan
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var housesGrid: some View {
        VStack(spacing: 12) {
            Text("12 Life Areas")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(1...12, id: \.self) { house in
                    houseCard(house: house)
                }
            }
        }
    }
    
    private var keyDifferenceNote: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("Different systems = different house positions")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.blue.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func quickStep(number: String, title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(.cyan)
                .clipShape(Circle())
            
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.cyan)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func planetRow(symbol: String, name: String, position: String) -> some View {
        HStack(spacing: 12) {
            Text(symbol)
                .font(.title2)
                .frame(width: 30)
            
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(position)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func houseCard(house: Int) -> some View {
        let meanings = [
            "Self", "Money", "Communication", "Home",
            "Fun", "Health", "Partners", "Transform",
            "Travel", "Career", "Friends", "Dreams"
        ]
        
        return VStack(spacing: 4) {
            Text("\(house)")
                .font(.callout.weight(.bold))
                .foregroundStyle(.cyan)
            
            Text(meanings[house - 1])
                .font(.caption2)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
            Text("Calculating your planetary positions...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            VStack(spacing: 16) {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 40)
                }
            }
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
              let _ = profile.birthLatitude,
              let _ = profile.birthLongitude,
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
        profile.birthLatitude ?? 0.0
    }
    
    var longitude: Double {
        profile.birthLongitude ?? 0.0
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
    @State private var selectedSystem: HouseSystem = .placidus
    @State private var animateHouse = false
    @State private var showComparison = false
    
    enum HouseSystem: String, CaseIterable {
        case placidus = "Placidus"
        case wholeSigns = "Whole Signs"
        case equal = "Equal House"
        case koch = "Koch"
        
        var description: String {
            switch self {
            case .placidus:
                return "Most popular system in Western astrology. Houses vary in size based on latitude."
            case .wholeSigns:
                return "Each house = one complete zodiac sign (30°). Oldest system used."
            case .equal:
                return "All houses are exactly 30° from the Ascendant. Simple and symmetric."
            case .koch:
                return "Similar to Placidus but uses different mathematical approach."
            }
        }
        
        var formula: String {
            switch self {
            case .placidus:
                return "tan(H) = tan(t) × sin(ε) / sin(φ + δ)"
            case .wholeSigns:
                return "House N = Ascendant Sign + (N-1) signs"
            case .equal:
                return "House N = Ascendant + (N-1) × 30°"
            case .koch:
                return "Based on time divisions of birth latitude"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleSection
                systemSelectorSection
                selectedSystemDetails
                houseMeaningsSection
                comparisonSection
                toggleComparisonButton
                keyInsightSection
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateHouse = true
            }
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("5. House Systems")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
            
            Text("12 Life Areas, Different Methods")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    private var systemSelectorSection: some View {
        VStack(spacing: 16) {
            Text("Choose a House System:")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(HouseSystem.allCases, id: \.self) { system in
                    systemSelectorCard(for: system)
                }
            }
        }
    }
    
    @ViewBuilder
    private func systemSelectorCard(for system: HouseSystem) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedSystem = system
            }
        } label: {
            VStack(spacing: 8) {
                let textColor = selectedSystem == system ? Color.black : Color.white
                let descriptionColor = selectedSystem == system ? Color.black.opacity(0.8) : Color.white.opacity(0.7)
                
                Text(system.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(textColor)
                
                Text(system.description)
                    .font(.caption)
                    .foregroundStyle(descriptionColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(12)
            .background {
                if selectedSystem == system {
                    Color.cyan
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var selectedSystemDetails: some View {
        VStack(spacing: 16) {
            Text("\(selectedSystem.rawValue) System")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.cyan)
            
            Text(selectedSystem.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            VStack(spacing: 8) {
                Text("Mathematical Formula:")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(selectedSystem.formula)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .padding(8)
                    .background(.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var houseMeaningsSection: some View {
        VStack(spacing: 16) {
            Text("The 12 Houses")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(1...12, id: \.self) { house in
                    houseCard(house: house)
                }
            }
        }
    }
    
    private var comparisonSection: some View {
        Group {
            if showComparison {
                VStack(spacing: 16) {
                    Text("System Comparison")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    comparisonTable
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var toggleComparisonButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                showComparison.toggle()
            }
        } label: {
            HStack {
                Image(systemName: showComparison ? "chevron.up" : "chevron.down")
                Text(showComparison ? "Hide Comparison" : "Compare Systems")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
    
    private var keyInsightSection: some View {
        VStack(spacing: 12) {
            Text("Why House Systems Differ")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Different house systems reflect different approaches to dividing the sky. Your choice affects which planets fall in which life areas, sometimes dramatically.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func houseCard(house: Int) -> some View {
        let meanings = [
            "Self & Identity", "Money & Values", "Communication", "Home & Family",
            "Creativity & Fun", "Health & Service", "Partnerships", "Transformation",
            "Philosophy & Travel", "Career & Status", "Friends & Hopes", "Subconscious"
        ]
        
        return VStack(spacing: 8) {
            Text("\(house)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.cyan)
            
            Text(meanings[house - 1])
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .scaleEffect(animateHouse ? 1.0 : 0.9)
        .opacity(animateHouse ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.5).delay(Double(house) * 0.05), value: animateHouse)
    }
    
    private var comparisonTable: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("House")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50)
                
                Text("Placidus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                
                Text("Whole Signs")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                
                Text("Equal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .padding(8)
            .background(.cyan.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Sample comparison data
            ForEach(1...6, id: \.self) { house in
                HStack {
                    Text("\(house)")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 50)
                    
                    Text(sampleDegree(for: house, system: .placidus))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                    
                    Text(sampleDegree(for: house, system: .wholeSigns))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                    
                    Text(sampleDegree(for: house, system: .equal))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func sampleDegree(for house: Int, system: HouseSystem) -> String {
        // Sample house cusp degrees for demonstration
        let base = 15.0 * Double(house - 1)
        switch system {
        case .placidus:
            return String(format: "%.1f°", base + Double.random(in: -5...5))
        case .wholeSigns:
            return String(format: "%.0f°", base)
        case .equal:
            return String(format: "%.1f°", base)
        case .koch:
            return String(format: "%.1f°", base + Double.random(in: -3...3))
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
                    Text("5. Your Chart")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("From Data to Insights")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Process Overview
                VStack(spacing: 12) {
                    Text("Your Chart Wheel")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.cyan)
                    
                    Text("12 houses + planetary positions = your cosmic blueprint")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
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
                
                // Summary Cards Section
                VStack(spacing: 12) {
                    Text("Summary: Data → Chart")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 8) {
                        summaryStep("📅", "Birth Data")
                        Text("→").foregroundStyle(.white.opacity(0.5))
                        summaryStep("🌍", "Location")
                        Text("→").foregroundStyle(.white.opacity(0.5))
                        summaryStep("⏰", "Sidereal")
                        Text("→").foregroundStyle(.white.opacity(0.5))
                        summaryStep("⭐", "Chart")
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
        ZStack {
            chartBackgroundView
            houseDivisionsView
            zodiacSignsView
            planetsView
        }
    }
    
    private var chartBackgroundView: some View {
        Group {
            // Outer circle (chart boundary)
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 2)
                .frame(width: 280, height: 280)
            
            // Inner circle
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)
        }
    }
    
    private var houseDivisionsView: some View {
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
    }
    
    private var zodiacSignsView: some View {
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
    }
    
    private var planetsView: some View {
        let planetData = [
            ("☉", 7.85, "Sun"), // Sun in Sagittarius 7°
            ("☽", 85.85, "Moon"), // Moon in Gemini 25°
            ("♂", 297.5, "Mars") // Mars in Capricorn 27°
        ]
        
        return Group {
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
    
    private func summaryStep(_ emoji: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
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
    @State private var showProUpgradeAlert = false
    
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
                showProUpgradeAlert = true
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
        .alert("Upgrade to Pro", isPresented: $showProUpgradeAlert) {
            Button("OK") { }
        } message: {
            Text("Unlock all planetary calculations and interpretations with Astronova Pro.")
        }
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
