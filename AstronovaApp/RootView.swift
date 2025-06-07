import SwiftUI

/// Decides which high-level screen to show based on authentication state.
struct RootView: View {
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                LoadingView()
            case .signedOut:
                OnboardingView()
            case .needsProfileSetup:
                SimpleProfileSetupView()
            case .signedIn:
                SimpleTabBarView()
            }
        }
    }
}

/// Beautiful, delightful onboarding with instant value and smooth animations
struct SimpleProfileSetupView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var currentStep = 0
    @State private var fullName = ""
    @State private var birthDate = Date()
    @State private var showingPersonalizedInsight = false
    @State private var showingConfetti = false
    @State private var personalizedInsight = ""
    @State private var animateStars = false
    @State private var animateGradient = false
    
    private let totalSteps = 3
    
    private var completionPercentage: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        ZStack {
            // Animated cosmic background
            LinearGradient(
                colors: [
                    Color(.systemIndigo).opacity(0.8),
                    Color(.systemPurple).opacity(0.6),
                    Color(.systemBlue).opacity(0.4)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating stars background
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: ["star.fill", "sparkles", "star.circle.fill"].randomElement()!)
                    .font(.system(size: CGFloat.random(in: 12...24)))
                    .foregroundStyle(.white.opacity(0.3))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...600)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.3),
                        value: animateStars
                    )
                    .offset(y: animateStars ? -20 : 20)
            }
            
            VStack(spacing: 0) {
                if !showingPersonalizedInsight {
                    // Elegant progress indicator
                    VStack(spacing: 12) {
                        HStack {
                            Text("✨ Creating Your Cosmic Profile")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(0..<totalSteps, id: \.self) { step in
                                Circle()
                                    .fill(step <= currentStep ? .white : .white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(step == currentStep ? 1.5 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentStep)
                            }
                            Spacer()
                            Text("\(currentStep + 1) / \(totalSteps)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                
                // Content area with beautiful card design
                TabView(selection: $currentStep) {
                    // Step 1: Welcome with value preview
                    EnhancedWelcomeStepView()
                        .tag(0)
                    
                    // Step 2: Name input with personality hint
                    EnhancedNameStepView(fullName: $fullName)
                        .tag(1)
                    
                    // Step 3: Birth date with instant insight
                    EnhancedBirthDateStepView(
                        birthDate: $birthDate,
                        onComplete: { insight in
                            personalizedInsight = insight
                            showPersonalizedInsight()
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                
                if !showingPersonalizedInsight {
                    // Beautiful action button
                    VStack(spacing: 16) {
                        Button {
                            handleContinue()
                        } label: {
                            HStack {
                                if currentStep == totalSteps - 1 {
                                    Image(systemName: "sparkles")
                                        .font(.title3.weight(.semibold))
                                    Text("Reveal My Cosmic Insight")
                                        .font(.title3.weight(.semibold))
                                } else {
                                    Text(currentStep == 0 ? "Begin Journey" : "Continue")
                                        .font(.title3.weight(.semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.title3.weight(.semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        }
                        .disabled(!canContinue)
                        .scaleEffect(canContinue ? 1.0 : 0.95)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canContinue)
                        
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    currentStep = max(0, currentStep - 1)
                                }
                            }
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
        }
        .overlay(
            // Personalized insight overlay
            Group {
                if showingPersonalizedInsight {
                    PersonalizedInsightView(
                        name: fullName,
                        insight: personalizedInsight,
                        onContinue: {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                showingPersonalizedInsight = false
                                showingConfetti = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                auth.completeProfileSetup()
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .overlay(
            ConfettiView(isActive: $showingConfetti)
                .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).delay(0.5)) {
                animateGradient = true
                animateStars = true
            }
        }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !fullName.isEmpty
        case 2: return true
        default: return false
        }
    }
    
    private func handleContinue() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if currentStep == totalSteps - 1 {
            // Generate personalized insight
            generatePersonalizedInsight()
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep = min(totalSteps - 1, currentStep + 1)
            }
        }
    }
    
    private func generatePersonalizedInsight() {
        let insights = [
            "Your birth on \(formatDate(birthDate)) reveals a powerful cosmic alignment. The stars suggest you have natural leadership qualities and a deep connection to creative energies.",
            "Born under the influence of \(formatDate(birthDate)), you carry the gift of intuition and emotional wisdom. The universe has blessed you with the ability to inspire others.",
            "The celestial patterns on \(formatDate(birthDate)) indicate a soul destined for transformation and growth. Your journey is one of continuous evolution and self-discovery.",
            "Your arrival on \(formatDate(birthDate)) marks you as someone with exceptional communication skills and a natural ability to bring harmony to challenging situations.",
            "The cosmic energies present on \(formatDate(birthDate)) suggest you have a unique blend of analytical mind and creative spirit, making you a natural problem-solver."
        ]
        
        personalizedInsight = insights.randomElement() ?? insights[0]
    }
    
    private func showPersonalizedInsight() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            showingPersonalizedInsight = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Onboarding Step Views

struct EnhancedWelcomeStepView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Animated cosmic icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeating)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.title2.weight(.light))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("Astronova")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Discover what the stars reveal about your personality, relationships, and destiny through personalized cosmic insights.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
}

struct EnhancedNameStepView: View {
    @Binding var fullName: String
    @State private var animateIcon = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Elegant person icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce.down, options: .repeating)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(spacing: 16) {
                    Text("What should we call you?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your name helps us create a personal connection with your cosmic journey.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                
                // Beautiful text field
                VStack(spacing: 8) {
                    TextField("", text: $fullName, prompt: Text("Enter your name").foregroundColor(.white.opacity(0.6)))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    
                    if !fullName.isEmpty {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("Perfect! The cosmos recognizes you, \(fullName.components(separatedBy: " ").first ?? fullName).")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: fullName.isEmpty)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
            // Auto-focus text field for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct EnhancedBirthDateStepView: View {
    @Binding var birthDate: Date
    let onComplete: (String) -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Animated calendar icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                    
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(spacing: 16) {
                    Text("When were you born?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your birth date reveals your sun sign and unlocks the cosmic blueprint of your personality.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                
                // Beautiful date picker
                VStack(spacing: 12) {
                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.1))
                    )
                    .colorScheme(.dark)
                    .padding(.horizontal, 24)
                    
                    Text("Selected: \(formatSelectedDate())")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                        )
                }
            }
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: birthDate)
    }
}

// MARK: - Personalized Insight View

struct PersonalizedInsightView: View {
    let name: String
    let insight: String
    let onContinue: () -> Void
    @State private var animateElements = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Blurred cosmic background
            Rectangle()
                .fill(.black.opacity(0.4))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main insight card
                VStack(spacing: 24) {
                    // Header with stars
                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                                    .scaleEffect(animateElements ? 1.2 : 1.0)
                            }
                        }
                        .animation(.easeInOut(duration: 1).delay(0.5), value: animateElements)
                        
                        Text("Your Cosmic Insight")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .opacity(showContent ? 1 : 0)
                    }
                    
                    // Personalized content
                    VStack(spacing: 16) {
                        Text("Hello, \(name.components(separatedBy: " ").first ?? name)! ✨")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .opacity(showContent ? 1 : 0)
                        
                        Text(insight)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .opacity(showContent ? 1 : 0)
                            .padding(.horizontal, 8)
                    }
                    
                    // Continue button
                    Button {
                        onContinue()
                    } label: {
                        HStack {
                            Text("Explore Your Cosmic Journey")
                                .font(.headline.weight(.semibold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.indigo, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
                    }
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .scaleEffect(animateElements ? 1 : 0.8)
                .opacity(animateElements ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateElements = true
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                showContent = true
            }
        }
    }
}


// MARK: - Confetti Animation

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
            }
        }
        .onChange(of: isActive) {
            if isActive {
                startConfetti()
            } else {
                confettiPieces.removeAll()
            }
        }
    }
    
    private func startConfetti() {
        confettiPieces.removeAll()
        
        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                size: Double.random(in: 5...15),
                color: [.red, .blue, .green, .yellow, .purple, .orange].randomElement()!,
                opacity: 1.0
            )
            confettiPieces.append(piece)
        }
        
        withAnimation(.easeOut(duration: 3.0)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y = UIScreen.main.bounds.height + 100
                confettiPieces[i].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isActive = false
        }
    }
}

struct ConfettiPiece {
    let id: Int
    var x: Double
    var y: Double
    let size: Double
    let color: Color
    var opacity: Double
}

// MARK: - Location Search Support

struct LocationSearchView: View {
    @Binding var query: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a city", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(searchResults, id: \.self) { result in
                    Button(result) {
                        query = result
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                searchResults = ["New York, NY", "Los Angeles, CA", "London, UK", "Mumbai, India", "Tokyo, Japan"]
            }
        }
    }
}

/// Simplified tab bar view
struct SimpleTabBarView: View {
    var body: some View {
        TabView {
            TodayTab()
                .tabItem { Label("Today", systemImage: "sun.max") }
            
            MatchTab()
                .tabItem { Label("Match", systemImage: "heart.circle") }
            
            ChatTab()
                .tabItem { Label("Chat", systemImage: "message") }
            
            ProfileTab()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

// MARK: - Simple Tab Views

struct TodayTab: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Today's date
                    HStack {
                        Text("Today's Horoscope")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    // Horoscope content
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🌟")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("Daily Insight")
                                    .font(.headline)
                                Text("Cosmic Guidance")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }
                        
                        Text("Today brings powerful energies for transformation and growth. The planetary alignments suggest this is an excellent time for introspection and setting new intentions. Trust your intuition as you navigate the day's opportunities.")
                            .font(.body)
                            .lineSpacing(4)
                        
                        Divider()
                        
                        // Key themes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Themes")
                                .font(.headline)
                            
                            HStack {
                                VStack {
                                    Text("💼")
                                        .font(.title3)
                                    Text("Career")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack {
                                    Text("❤️")
                                        .font(.title3)
                                    Text("Love")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack {
                                    Text("🌱")
                                        .font(.title3)
                                    Text("Growth")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack {
                                    Text("⚖️")
                                        .font(.title3)
                                    Text("Balance")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Divider()
                        
                        // Lucky elements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Lucky Elements")
                                .font(.headline)
                            
                            HStack {
                                Label("Purple", systemImage: "circle.fill")
                                    .foregroundStyle(Color.purple)
                                Spacer()
                                Label("7", systemImage: "star.fill")
                                    .foregroundStyle(Color.yellow)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Planetary positions preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Planetary Energies")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            PlanetCard(symbol: "☉", name: "Sun", sign: "Sagittarius")
                            PlanetCard(symbol: "☽", name: "Moon", sign: "Pisces")
                            PlanetCard(symbol: "☿", name: "Mercury", sign: "Capricorn")
                            PlanetCard(symbol: "♀", name: "Venus", sign: "Scorpio")
                            PlanetCard(symbol: "♂", name: "Mars", sign: "Leo")
                            PlanetCard(symbol: "♃", name: "Jupiter", sign: "Taurus")
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Today")
        }
    }
}

struct PlanetCard: View {
    let symbol: String
    let name: String
    let sign: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.title2)
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
            Text(sign)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MatchTab: View {
    @State private var partnerName = ""
    @State private var partnerBirthDate = Date()
    @State private var showingResults = false
    @State private var showingContactsPicker = false
    @State private var animateHearts = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Beautiful header with animated hearts
                    VStack(spacing: 20) {
                        HStack {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundStyle(.pink)
                                    .scaleEffect(animateHearts ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.3),
                                        value: animateHearts
                                    )
                            }
                        }
                        
                        VStack(spacing: 12) {
                            Text("Compatibility Check")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            Text("Discover what the stars say about your connection with friends, family, or that special someone")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Quick access from contacts
                    Button {
                        showingContactsPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose from Contacts")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Quick compatibility check")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.blue.opacity(0.08))
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Manual input form
                    VStack(spacing: 20) {
                        HStack {
                            Text("Or enter details manually")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // Name input with beautiful styling
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("Friend, family member, partner...", text: $partnerName)
                                    .font(.body)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.gray.opacity(0.08))
                                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Birth date with elegant picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Date")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                DatePicker("", selection: $partnerBirthDate, in: ...Date(), displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.gray.opacity(0.08))
                                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Beautiful analyze button
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showingResults.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.title3.weight(.semibold))
                                    Text("Reveal Compatibility")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [.pink, .purple, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 26))
                                .shadow(color: .pink.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(partnerName.isEmpty)
                            .scaleEffect(partnerName.isEmpty ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: partnerName.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Beautiful results section
                    if showingResults {
                        VStack(spacing: 20) {
                            // Compatibility score with animation
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "heart.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.pink)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Compatibility Score")
                                            .font(.headline)
                                        Text("Based on cosmic alignment")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("89%")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.green.opacity(0.08))
                                        .stroke(.green.opacity(0.2), lineWidth: 1)
                                )
                                
                                Text("Great cosmic connection! You and \(partnerName.isEmpty ? "this person" : partnerName) share harmonious energy patterns that suggest strong compatibility in communication and shared values.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 8)
                            }
                            
                            // Compatibility breakdown
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                CompatibilityCard(title: "Emotional", score: 92, color: .purple)
                                CompatibilityCard(title: "Mental", score: 88, color: .blue)
                                CompatibilityCard(title: "Physical", score: 85, color: .pink)
                                CompatibilityCard(title: "Spiritual", score: 91, color: .green)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingResults)
                    }
                    
                    // Recent matches (simplified)
                    if !sampleMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Checks")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(sampleMatches, id: \.name) { match in
                                HStack {
                                    Circle()
                                        .fill(.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(match.name.prefix(1)))
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(.blue)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(match.name)
                                            .font(.callout.weight(.medium))
                                        Text("Compatibility check")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(match.score)%")
                                        .font(.callout.weight(.bold))
                                        .foregroundStyle(match.score >= 80 ? .green : match.score >= 60 ? .orange : .red)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.gray.opacity(0.05))
                                        .stroke(.gray.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Match")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingContactsPicker) {
            ContactsPickerView(selectedName: $partnerName)
        }
        .onAppear {
            animateHearts = true
        }
    }
    
    private let sampleMatches = [
        (name: "Sarah", score: 92),
        (name: "Alex", score: 78),
        (name: "Jordan", score: 85)
    ]
}

struct CompatibilityCard: View {
    let title: String
    let score: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
            Text("\(score)%")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ChatTab: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", text: "Welcome! I'm your AI astrologer. How can I help guide you today?", isUser: false),
        ChatMessage(id: "2", text: "What does my birth chart say about my career?", isUser: true),
        ChatMessage(id: "3", text: "Based on your chart, you have strong leadership qualities with your Leo rising. Your 10th house placement suggests success in creative or executive roles. This is an excellent time to pursue your career goals!", isUser: false)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    ChatBubble(text: message.text, isUser: true)
                                } else {
                                    ChatBubble(text: message.text, isUser: false)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Input area
                HStack {
                    TextField("Ask about your chart, love life, career...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(Color.white)
                            .frame(width: 32, height: 32)
                            .background(messageText.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                
                // Quick questions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickQuestions, id: \.self) { question in
                            Button(question) {
                                messageText = question
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("AI Astrologer")
        }
    }
    
    private let quickQuestions = [
        "What's my love forecast?",
        "Career guidance?",
        "Today's energy?",
        "Mercury retrograde effects?",
        "Best time for decisions?"
    ]
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(id: UUID().uuidString, text: messageText, isUser: true)
        messages.append(userMessage)
        
        // Clear input
        let currentMessage = messageText
        messageText = ""
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateResponse(for: currentMessage)
            let aiMessage = ChatMessage(id: UUID().uuidString, text: response, isUser: false)
            messages.append(aiMessage)
        }
    }
    
    private func generateResponse(for message: String) -> String {
        let responses = [
            "The stars suggest this is a transformative time for you. Trust your intuition and embrace the changes coming your way.",
            "Your birth chart shows strong creative energy. Channel this into projects that inspire you.",
            "The current planetary alignments favor communication and relationships. Reach out to loved ones.",
            "With Jupiter in your sector, expansion and growth opportunities are on the horizon.",
            "The Moon's position suggests emotional clarity. This is a good time for important decisions."
        ]
        return responses.randomElement() ?? "The cosmos are aligning to bring you clarity and guidance."
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        Text(text)
            .padding(12)
            .background(isUser ? Color.blue : Color.gray.opacity(0.2))
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .cornerRadius(16)
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }
}




struct ProfileTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var bookmarkedReadings: [BookmarkedReading] = []
    
    private let tabs = ["Calendar", "Charts", "Bookmarks"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Text(tabs[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        CalendarHoroscopeView(
                            selectedDate: $selectedDate,
                            onBookmark: bookmarkReading
                        )
                    case 1:
                        InteractiveChartsView(
                            selectedDate: selectedDate
                        )
                    case 2:
                        BookmarkedReadingsView(
                            bookmarks: bookmarkedReadings,
                            onRemove: removeBookmark
                        )
                    default:
                        CalendarHoroscopeView(
                            selectedDate: $selectedDate,
                            onBookmark: bookmarkReading
                        )
                    }
                }
            }
            .navigationTitle("Horoscope Hub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(auth: auth)
        }
    }
    
    private func bookmarkReading(_ reading: HoroscopeReading) {
        let bookmark = BookmarkedReading(
            id: UUID(),
            date: reading.date,
            type: reading.type,
            title: reading.title,
            content: reading.content,
            createdAt: Date()
        )
        bookmarkedReadings.append(bookmark)
    }
    
    private func removeBookmark(_ bookmark: BookmarkedReading) {
        bookmarkedReadings.removeAll { $0.id == bookmark.id }
    }
}

// MARK: - Calendar Horoscope View

struct CalendarHoroscopeView: View {
    @Binding var selectedDate: Date
    let onBookmark: (HoroscopeReading) -> Void
    
    @State private var showingMonthPicker = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Calendar Header with Month Navigation
                CalendarHeaderView(
                    selectedDate: $selectedDate,
                    showingMonthPicker: $showingMonthPicker
                )
                
                // Compact Calendar Grid
                CalendarGridView(selectedDate: $selectedDate)
                
                // Daily Synopsis (Free)
                DailySynopsisCard(
                    date: selectedDate,
                    onBookmark: onBookmark
                )
                
                // Premium Content Teasers
                PremiumContentTeasers(date: selectedDate)
            }
            .padding()
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerView(selectedDate: $selectedDate)
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var showingMonthPicker: Bool
    
    var body: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Button {
                showingMonthPicker = true
            } label: {
                VStack(spacing: 4) {
                    Text(DateFormatter.monthYear.string(from: selectedDate))
                        .font(.title2.weight(.semibold))
                    Text("Tap to change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Weekday headers
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(height: 30)
            }
            
            // Calendar days
            ForEach(daysInMonth, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    selectedDate: $selectedDate,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    hasReading: hasHoroscopeReading(for: date)
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        
        let monthStart = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        var date = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: monthStart)!
        
        // Generate 42 days (6 weeks)
        for _ in 0..<42 {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return days
    }
    
    private func hasHoroscopeReading(for date: Date) -> Bool {
        !Calendar.current.isDate(date, inSameDayAs: Date().addingTimeInterval(86400))
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let isSelected: Bool
    let isToday: Bool
    let hasReading: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button {
            selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(textColor)
                
                if hasReading {
                    Circle()
                        .fill(.blue)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .blue }
        if !calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) { return .secondary }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isSelected { return .blue }
        if isToday { return .blue.opacity(0.2) }
        return .clear
    }
}

struct DailySynopsisCard: View {
    let date: Date
    let onBookmark: (HoroscopeReading) -> Void
    
    @State private var reading: HoroscopeReading?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Synopsis")
                        .font(.headline)
                    Text(DateFormatter.fullDate.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let reading = reading {
                    Button {
                        onBookmark(reading)
                    } label: {
                        Image(systemName: "bookmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if let reading = reading {
                Text(reading.content)
                    .font(.callout)
                    .lineSpacing(4)
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.orange)
                    Text("Free daily insight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading daily synopsis...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task {
            await loadDailyReading()
        }
        .onChange(of: date) {
            Task { await loadDailyReading() }
        }
    }
    
    @MainActor
    private func loadDailyReading() async {
        try? await Task.sleep(for: .milliseconds(500))
        
        reading = HoroscopeReading(
            id: UUID(),
            date: date,
            type: .daily,
            title: "Daily Synopsis",
            content: generateDailySynopsis(for: date)
        )
    }
    
    private func generateDailySynopsis(for date: Date) -> String {
        let insights = [
            "The cosmic energies today bring opportunities for personal growth and meaningful connections.",
            "Your intuition is heightened today, making it an excellent time for important decisions.",
            "Creative energy flows strongly through you today, perfect for artistic pursuits.",
            "Focus on relationships and communication today as the planets align favorably.",
            "Financial opportunities may present themselves today - stay alert to possibilities."
        ]
        return insights.randomElement() ?? insights[0]
    }
}

struct PremiumContentTeasers: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Unlock Detailed Insights")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                PremiumTeaserCard(
                    title: "Love Forecast",
                    description: "Detailed romantic insights",
                    icon: "heart.fill",
                    color: .pink,
                    price: "$2.99"
                )
                
                PremiumTeaserCard(
                    title: "Birth Chart Reading",
                    description: "Complete natal analysis",
                    icon: "circle.grid.cross.fill",
                    color: .purple,
                    price: "$9.99"
                )
                
                PremiumTeaserCard(
                    title: "Career Forecast",
                    description: "Professional guidance",
                    icon: "briefcase.fill",
                    color: .blue,
                    price: "$4.99"
                )
                
                PremiumTeaserCard(
                    title: "Year Ahead",
                    description: "12-month outlook",
                    icon: "calendar",
                    color: .green,
                    price: "$19.99"
                )
            }
        }
    }
}

struct PremiumTeaserCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let price: String
    
    var body: some View {
        Button {
            // Handle premium purchase
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text(price)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Interactive Charts View

struct InteractiveChartsView: View {
    let selectedDate: Date
    
    @State private var selectedChart = 0
    
    private let chartTypes = ["Birth Chart", "Transit Chart", "Progressions"]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Chart Type Selector
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(chartTypes.indices, id: \.self) { index in
                        Text(chartTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Chart Display
                Group {
                    switch selectedChart {
                    case 0:
                        BirthChartView()
                    case 1:
                        TransitChartView(date: selectedDate)
                    case 2:
                        ProgressionChartView(date: selectedDate)
                    default:
                        BirthChartView()
                    }
                }
                
                // Chart Legend
                ChartLegendView()
            }
            .padding()
        }
    }
}

struct BirthChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Birth Chart")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("🌟")
                    .font(.system(size: 60))
                
                Text("Interactive Birth Chart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct TransitChartView: View {
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transit Chart - \(DateFormatter.shortDate.string(from: date))")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("🌙")
                    .font(.system(size: 60))
                
                Text("Current Transits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ProgressionChartView: View {
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progressions - \(DateFormatter.shortDate.string(from: date))")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(.purple.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("⭐")
                    .font(.system(size: 60))
                
                Text("Secondary Progressions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ChartLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Legend")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LegendItem(symbol: "☉", name: "Sun", color: .orange)
                LegendItem(symbol: "☽", name: "Moon", color: .blue)
                LegendItem(symbol: "☿", name: "Mercury", color: .gray)
                LegendItem(symbol: "♀", name: "Venus", color: .pink)
                LegendItem(symbol: "♂", name: "Mars", color: .red)
                LegendItem(symbol: "♃", name: "Jupiter", color: .green)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct LegendItem: View {
    let symbol: String
    let name: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text(name)
                .font(.callout)
            Spacer()
        }
    }
}

// MARK: - Bookmarked Readings View

struct BookmarkedReadingsView: View {
    let bookmarks: [BookmarkedReading]
    let onRemove: (BookmarkedReading) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if bookmarks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No Bookmarked Readings")
                            .font(.title2)
                        
                        Text("Bookmark your favorite horoscope readings to find them here.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(bookmarks) { bookmark in
                        BookmarkCard(bookmark: bookmark) {
                            onRemove(bookmark)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct BookmarkCard: View {
    let bookmark: BookmarkedReading
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.title)
                        .font(.headline)
                    Text(DateFormatter.fullDate.string(from: bookmark.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            Text(bookmark.content)
                .font(.callout)
                .lineSpacing(3)
            
            HStack {
                Text(bookmark.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2), in: Capsule())
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("Saved \(DateFormatter.relative.string(from: bookmark.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views and Models

struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Month",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SettingsView: View {
    let auth: AuthState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    Button("Sign Out", role: .destructive) {
                        auth.signOut()
                    }
                }
                
                Section("Notifications") {
                    Toggle("Daily Horoscope", isOn: .constant(true))
                    Toggle("Premium Content", isOn: .constant(false))
                }
                
                Section("About") {
                    Text("Astronova v1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Data Models

struct HoroscopeReading {
    let id: UUID
    let date: Date
    let type: ReadingType
    let title: String
    let content: String
}

struct BookmarkedReading: Identifiable {
    let id: UUID
    let date: Date
    let type: ReadingType
    let title: String
    let content: String
    let createdAt: Date
}

enum ReadingType {
    case daily
    case love
    case career
    case birthChart
    case yearAhead
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .love: return "Love"
        case .career: return "Career"
        case .birthChart: return "Birth Chart"
        case .yearAhead: return "Year Ahead"
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Contacts Picker

struct ContactsPickerView: View {
    @Binding var selectedName: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var hasContactsAccess = false
    @State private var mockContacts: [MockContact] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if hasContactsAccess {
                    // Search bar
                    TextField("Search contacts", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    // Contacts list
                    List(filteredContacts, id: \.id) { contact in
                        Button {
                            selectedName = contact.name
                            dismiss()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(contact.initials)
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                    if !contact.relationship.isEmpty {
                                        Text(contact.relationship)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Access request view
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 12) {
                            Text("Access Your Contacts")
                                .font(.title2.weight(.semibold))
                            
                            Text("Choose from your contacts to quickly analyze compatibility with friends, family, and loved ones.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        
                        Button("Grant Access") {
                            requestContactsAccess()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                        
                        Button("Maybe Later") {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadMockContacts()
            }
        }
    }
    
    private var filteredContacts: [MockContact] {
        if searchText.isEmpty {
            return mockContacts
        } else {
            return mockContacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func requestContactsAccess() {
        // Simulate contacts access grant
        withAnimation {
            hasContactsAccess = true
        }
    }
    
    private func loadMockContacts() {
        mockContacts = [
            MockContact(name: "Sarah Johnson", relationship: "Friend"),
            MockContact(name: "Michael Chen", relationship: "Colleague"),
            MockContact(name: "Emma Rodriguez", relationship: "Sister"),
            MockContact(name: "David Kim", relationship: "Partner"),
            MockContact(name: "Lisa Thompson", relationship: "Friend"),
            MockContact(name: "Alex Morgan", relationship: "Cousin"),
            MockContact(name: "Rachel Green", relationship: "College Friend"),
            MockContact(name: "James Wilson", relationship: "Neighbor"),
            MockContact(name: "Maya Patel", relationship: "Work Friend"),
            MockContact(name: "Tom Anderson", relationship: "Brother")
        ]
    }
}

struct MockContact {
    let id = UUID()
    let name: String
    let relationship: String
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return String(first + last).uppercased()
    }
}