import SwiftUI

struct PlanetaryCalculationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var currentStep = 0
    @State private var animateElements = false
    
    private let totalSteps = 6
    private let freeSteps = 2 // Free users see steps 0 and 1
    
    var body: some View {
        NavigationView {
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
                        if auth.subscriptionManager.isProUser {
                            SiderealTimeAnimationView()
                                .tag(2)
                            
                            PlanetaryCalculationView()
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
            ForEach(0..<30, id: \.self) { i in
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
                    if currentStep >= freeSteps && !auth.subscriptionManager.isProUser {
                        Button {
                            // Show Pro upgrade flow
                            auth.subscriptionManager.showPaywall()
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
        } else if step >= freeSteps && !auth.subscriptionManager.isProUser {
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
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("4. Planetary Positions")
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
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("6. Aspect Calculation")
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
                auth.subscriptionManager.showPaywall()
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