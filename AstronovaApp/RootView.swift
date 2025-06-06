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
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    @State private var showingPersonalizedInsight = false
    @State private var showingConfetti = false
    @State private var personalizedInsight = ""
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    private let totalSteps = 5
    
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
                    EnhancedBirthDateStepView(birthDate: $birthDate)
                        .tag(2)
                    
                    // Step 4: Birth time input
                    EnhancedBirthTimeStepView(birthTime: $birthTime)
                        .tag(3)
                    
                    // Step 5: Birth place input with completion
                    EnhancedBirthPlaceStepView(
                        birthPlace: $birthPlace,
                        onComplete: { insight in
                            personalizedInsight = insight
                            showPersonalizedInsight()
                        }
                    )
                    .tag(4)
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
        case 3: return true
        case 4: return !birthPlace.isEmpty
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
        // Save the profile data with error handling
        auth.profileManager.profile.fullName = fullName
        auth.profileManager.profile.birthDate = birthDate
        auth.profileManager.profile.birthTime = birthTime
        auth.profileManager.profile.birthPlace = birthPlace
        
        // Attempt to save the profile with error handling
        do {
            try auth.profileManager.saveProfile()
        } catch {
            saveError = "Failed to save profile: \(error.localizedDescription)"
            showingSaveError = true
            print("Profile save error: \(error)")
            // Continue with insight generation even if save fails
        }
        
        let insights = [
            "Your birth on \(formatDate(birthDate)) at \(formatTime(birthTime)) in \(birthPlace) reveals a powerful cosmic alignment. The stars suggest you have natural leadership qualities and a deep connection to creative energies.",
            "Born under the influence of \(formatDate(birthDate)) in \(birthPlace), you carry the gift of intuition and emotional wisdom. The universe has blessed you with the ability to inspire others.",
            "The celestial patterns on \(formatDate(birthDate)) at \(formatTime(birthTime)) indicate a soul destined for transformation and growth. Your journey is one of continuous evolution and self-discovery.",
            "Your arrival on \(formatDate(birthDate)) in \(birthPlace) marks you as someone with exceptional communication skills and a natural ability to bring harmony to challenging situations.",
            "The cosmic energies present on \(formatDate(birthDate)) at \(formatTime(birthTime)) suggest you have a unique blend of analytical mind and creative spirit, making you a natural problem-solver."
        ]
        
        personalizedInsight = insights.randomElement() ?? insights[0]
        showPersonalizedInsight()
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
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
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

struct EnhancedBirthTimeStepView: View {
    @Binding var birthTime: Date
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Animated clock icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                    
                    Image(systemName: "clock.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(spacing: 16) {
                    Text("What time were you born?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your birth time is crucial for calculating your rising sign and precise planetary positions.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                
                // Beautiful time picker
                VStack(spacing: 12) {
                    DatePicker(
                        "",
                        selection: $birthTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.1))
                    )
                    .colorScheme(.dark)
                    .padding(.horizontal, 24)
                    
                    Text("Selected: \(formatSelectedTime())")
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
    
    private func formatSelectedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: birthTime)
    }
}

struct EnhancedBirthPlaceStepView: View {
    @Binding var birthPlace: String
    let onComplete: (String) -> Void
    @State private var animateIcon = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Animated location icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                    
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce.down, options: .repeating)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(spacing: 16) {
                    Text("Where were you born?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your birth location helps us calculate the exact positions of celestial bodies at the moment of your birth.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                
                // Beautiful text field
                VStack(spacing: 8) {
                    TextField("", text: $birthPlace, prompt: Text("City, State/Country").foregroundColor(.white.opacity(0.6)))
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
                    
                    if !birthPlace.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text("Perfect! Your cosmic map is ready to be revealed.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: birthPlace.isEmpty)
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

/// Simplified tab bar view with first-run guidance
struct SimpleTabBarView: View {
    @State private var selectedTab = 0
    @State private var showTabGuide = false
    @State private var guideStep = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch selectedTab {
                case 0:
                    TodayTab()
                case 1:
                    FriendsTab()
                case 2:
                    NexusTab()
                case 3:
                    ProfileTab()
                default:
                    TodayTab()
                }
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .overlay(
            // First-run tab guide overlay
            Group {
                if showTabGuide {
                    TabGuideOverlay(
                        step: guideStep,
                        onNext: {
                            if guideStep < 3 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    guideStep += 1
                                    selectedTab = guideStep
                                }
                            } else {
                                dismissGuide()
                            }
                        },
                        onSkip: dismissGuide
                    )
                }
            }
        )
        .onAppear {
            trackAppLaunch()
            showFirstRunGuideIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tabIndex = notification.object as? Int {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = tabIndex
                }
            }
        }
    }
    
    private func trackAppLaunch() {
        let count = UserDefaults.standard.integer(forKey: "app_launch_count")
        UserDefaults.standard.set(count + 1, forKey: "app_launch_count")
    }
    
    private func showFirstRunGuideIfNeeded() {
        let launchCount = UserDefaults.standard.integer(forKey: "app_launch_count")
        let hasSeenGuide = UserDefaults.standard.bool(forKey: "has_seen_tab_guide")
        
        if launchCount <= 2 && !hasSeenGuide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showTabGuide = true
                }
            }
        }
    }
    
    private func dismissGuide() {
        withAnimation(.easeOut(duration: 0.3)) {
            showTabGuide = false
        }
        UserDefaults.standard.set(true, forKey: "has_seen_tab_guide")
    }
}

// MARK: - Custom Tab Icons

struct FriendsTabIcon: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Constellation pattern for friends
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 3, height: 3)
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 2, height: 2)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 2, height: 2)
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 2, height: 2)
                }
                HStack(spacing: 2) {
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 2, height: 2)
                    Circle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 3, height: 3)
                }
            }
            
            // Connection lines
            if isSelected {
                Path { path in
                    path.move(to: CGPoint(x: 5, y: 3))
                    path.addLine(to: CGPoint(x: 10, y: 8))
                    path.addLine(to: CGPoint(x: 15, y: 3))
                    path.move(to: CGPoint(x: 5, y: 15))
                    path.addLine(to: CGPoint(x: 15, y: 15))
                }
                .stroke(Color.primary.opacity(0.3), lineWidth: 0.5)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct NexusTabIcon: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Cosmic terminal design
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? .primary : .secondary, lineWidth: 1.5)
                .frame(width: 20, height: 16)
            
            // Terminal cursor/cosmic elements
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 6, height: 1)
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .opacity(isSelected ? 1.0 : 0.5)
                        .frame(width: 3, height: 1)
                }
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .opacity(isSelected ? 1.0 : 0.7)
                        .frame(width: 4, height: 1)
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 2, height: 1)
                }
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 1, height: 1)
                    Rectangle()
                        .fill(isSelected ? .primary : .secondary)
                        .frame(width: 1, height: 1)
                        .opacity(isSelected ? 1.0 : 0.3)
                }
            }
            
            // Cosmic sparkle
            if isSelected {
                Circle()
                    .fill(.primary)
                    .frame(width: 2, height: 2)
                    .offset(x: 10, y: -8)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct ProfileTabIcon: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Astrological chart wheel
            Circle()
                .stroke(isSelected ? .primary : .secondary, lineWidth: 1.5)
                .frame(width: 20, height: 20)
            
            // Inner circle for essence/soul
            Circle()
                .stroke(isSelected ? .primary : .secondary, lineWidth: 1)
                .opacity(isSelected ? 1.0 : 0.6)
                .frame(width: 12, height: 12)
            
            // Zodiac divisions (simplified)
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(isSelected ? .primary : .secondary)
                    .frame(width: 1, height: 6)
                    .offset(y: -7)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            
            // Center soul point
            Circle()
                .fill(isSelected ? .primary : .secondary)
                .frame(width: 3, height: 3)
            
            // Moon phase indicator
            if isSelected {
                Circle()
                    .fill(.primary)
                    .frame(width: 4, height: 4)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 2)
                            Rectangle()
                                .fill(.clear)
                                .frame(width: 2)
                        }
                    )
                    .offset(x: 12, y: -8)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        (title: "Today", icon: "sun.and.horizon.circle.fill", customIcon: nil),
        (title: "Friends", icon: "", customIcon: "friends"),
        (title: "Nexus", icon: "", customIcon: "nexus"), 
        (title: "Profile", icon: "", customIcon: "profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Icon
                        Group {
                            if let customIcon = tabs[index].customIcon {
                                switch customIcon {
                                case "friends":
                                    FriendsTabIcon(isSelected: selectedTab == index)
                                case "nexus":
                                    NexusTabIcon(isSelected: selectedTab == index)
                                case "profile":
                                    ProfileTabIcon(isSelected: selectedTab == index)
                                default:
                                    Image(systemName: tabs[index].icon)
                                        .font(.title3)
                                }
                            } else {
                                Image(systemName: tabs[index].icon)
                                    .font(.title3)
                            }
                        }
                        .foregroundStyle(selectedTab == index ? .primary : .secondary)
                        .accessibilityHidden(true)
                        
                        // Title
                        Text(tabs[index].title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(selectedTab == index ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].title)
                .accessibilityHint("Tab \(index + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(
            .ultraThinMaterial,
            in: Rectangle()
        )
        .overlay(
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Simple Tab Views

struct TodayTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingWelcome = false
    @State private var animateWelcome = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome header for new users
                    if shouldShowWelcome {
                        WelcomeToTodayCard(onDismiss: {
                            showingWelcome = false
                        })
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Primary CTA section
                    PrimaryCTASection()
                    
                    // Today's date
                    HStack {
                        Text("Today's Horoscope")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    // Horoscope content with enhanced visuals
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
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue.opacity(0.1), lineWidth: 1)
                    )
                    
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
                    
                    // Discovery CTAs
                    DiscoveryCTASection()
                    
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Today")
        }
        .onAppear {
            if shouldShowWelcome {
                showingWelcome = true
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5)) {
                    animateWelcome = true
                }
            }
        }
    }
    
    private var shouldShowWelcome: Bool {
        // Show welcome for first few app opens
        UserDefaults.standard.integer(forKey: "app_launch_count") < 3
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

// MARK: - Welcome and CTA Components

struct WelcomeToTodayCard: View {
    let onDismiss: () -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Your Cosmic Journey!")
                        .font(.headline.weight(.semibold))
                    Text("Your personalized daily guidance awaits")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                Text("💫")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explore the app")
                        .font(.callout.weight(.medium))
                    Text("• Check daily insights below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Find compatibility matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Chat with your AI astrologer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            animateIcon = true
        }
    }
}

struct PrimaryCTASection: View {
    @State private var animateGradient = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CTACard(
                    title: "Check Compatibility",
                    subtitle: "With someone special",
                    icon: "heart.circle.fill",
                    color: .pink,
                    action: {
                        switchToTab(1) // Switch to Match tab
                    }
                )
                
                CTACard(
                    title: "Ask the Stars",
                    subtitle: "AI guidance & insights",
                    icon: "message.circle.fill",
                    color: .blue,
                    action: {
                        switchToTab(2) // Switch to Chat tab
                    }
                )
            }
        }
    }
    
    private func switchToTab(_ index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Post notification to switch tabs
        NotificationCenter.default.post(name: .switchToTab, object: index)
    }
}

struct CTACard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct DiscoveryCTASection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Discover More")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                DiscoveryCard(
                    title: "Explore Your Birth Chart",
                    description: "Dive deep into your cosmic blueprint and personality insights",
                    icon: "circle.grid.cross.fill",
                    color: .purple,
                    action: {
                        switchToProfileCharts()
                    }
                )
                
                DiscoveryCard(
                    title: "Track Planetary Transits",
                    description: "See how current cosmic events affect your daily life",
                    icon: "globe",
                    color: .green,
                    action: {
                        switchToProfileCharts()
                    }
                )
                
                DiscoveryCard(
                    title: "Save Your Favorite Readings",
                    description: "Bookmark insights that resonate with you for future reference",
                    icon: "bookmark.circle.fill",
                    color: .orange,
                    action: {
                        switchToProfileBookmarks()
                    }
                )
            }
        }
    }
    
    private func switchToProfileCharts() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Switch to Profile tab and then to Charts section
        NotificationCenter.default.post(name: .switchToTab, object: 3)
        NotificationCenter.default.post(name: .switchToProfileSection, object: 1)
    }
    
    private func switchToProfileBookmarks() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Switch to Profile tab and then to Bookmarks section
        NotificationCenter.default.post(name: .switchToTab, object: 3)
        NotificationCenter.default.post(name: .switchToProfileSection, object: 2)
    }
}

struct DiscoveryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FriendsTab: View {
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
            .navigationTitle("Friends")
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

struct NexusTab: View {
    @State private var messageText = ""
    @State private var messages: [CosmicMessage] = [
        CosmicMessage(id: "1", text: "✨ Welcome to the Cosmic Nexus! I'm your AI astrologer, here to illuminate your path through the stars. What cosmic wisdom can I share with you today?", isUser: false, messageType: .welcome, timestamp: Date().addingTimeInterval(-3600)),
        CosmicMessage(id: "2", text: "What does my birth chart say about my career?", isUser: true, messageType: .question, timestamp: Date().addingTimeInterval(-1800)),
        CosmicMessage(id: "3", text: "🌟 The celestial patterns in your chart reveal fascinating insights! With your Leo rising, you radiate natural leadership energy. Your 10th house placement indicates powerful potential in creative or executive roles. The stars are aligning beautifully for your career aspirations right now! ✨", isUser: false, messageType: .insight, timestamp: Date().addingTimeInterval(-900))
    ]
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var showingTypingIndicator = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Cosmic animated background
                CosmicChatBackground(animateStars: $animateStars, animateGradient: $animateGradient)
                
                VStack(spacing: 0) {
                    // Chat messages with cosmic styling
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(messages) { message in
                                CosmicMessageView(message: message)
                            }
                            
                            // Typing indicator
                            if showingTypingIndicator {
                                CosmicTypingIndicator()
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    
                    // Cosmic input area
                    CosmicInputArea(
                        messageText: $messageText,
                        onSend: sendMessage,
                        onQuickQuestion: { question in
                            messageText = question
                        }
                    )
                }
            }
            .navigationTitle("Cosmic Nexus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).delay(0.3)) {
                animateStars = true
                animateGradient = true
            }
        }
    }
    
    private let quickQuestions = [
        "What's my love forecast? 💖",
        "Career guidance? ⭐",
        "Today's energy? ☀️",
        "Mercury retrograde effects? ☿",
        "Best time for decisions? 🌙"
    ]
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Add user message
        let userMessage = CosmicMessage(
            id: UUID().uuidString,
            text: messageText,
            isUser: true,
            messageType: .question,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            messages.append(userMessage)
        }
        
        // Clear input and show typing indicator
        let currentMessage = messageText
        messageText = ""
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingTypingIndicator = true
        }
        
        // Simulate AI response with realistic delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingTypingIndicator = false
            }
            
            let response = generateCosmicResponse(for: currentMessage)
            let messageType: CosmicMessageType = response.contains("🌟") ? .insight : .guidance
            
            let aiMessage = CosmicMessage(
                id: UUID().uuidString,
                text: response,
                isUser: false,
                messageType: messageType,
                timestamp: Date()
            )
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                messages.append(aiMessage)
            }
        }
    }
    
    private func generateCosmicResponse(for message: String) -> String {
        let lowerMessage = message.lowercased()
        
        if lowerMessage.contains("love") || lowerMessage.contains("relationship") || lowerMessage.contains("romance") {
            let loveResponses = [
                "💖 The cosmos whispers of beautiful romantic energy surrounding you! Venus is dancing through your 7th house, bringing opportunities for deep, meaningful connections. Open your heart to the magic that awaits.",
                "🌹 Love flows through the celestial currents toward you! The Moon's gentle influence suggests emotional harmony and the potential for a significant romantic encounter this lunar cycle.",
                "✨ Your love chakra is radiating powerful energy! The stars indicate that someone special may enter your orbit soon. Trust the universe's timing - it's always perfect."
            ]
            return loveResponses.randomElement() ?? loveResponses[0]
        }
        
        if lowerMessage.contains("career") || lowerMessage.contains("work") || lowerMessage.contains("job") {
            let careerResponses = [
                "🌟 Your professional constellation is shining brilliantly! Mars in your 10th house brings dynamic energy for career advancement. This is your time to step into your power and leadership role.",
                "⭐ The cosmic winds are shifting in your favor professionally! Jupiter's expansive energy suggests new opportunities will manifest soon. Prepare to embrace your destiny.",
                "✨ Your career path is illuminated by stellar influences! The Sun's position indicates recognition and success are approaching. Trust your unique talents and let them shine."
            ]
            return careerResponses.randomElement() ?? careerResponses[0]
        }
        
        if lowerMessage.contains("today") || lowerMessage.contains("energy") || lowerMessage.contains("now") {
            let energyResponses = [
                "🌞 Today's cosmic energy flows with transformative power! The planetary alignments create a portal for manifestation. Set your intentions and watch the universe respond.",
                "⚡ Electric energy courses through the celestial realm today! This is a perfect time for new beginnings and releasing what no longer serves your highest good.",
                "🌙 The lunar energies today bring intuitive clarity and emotional balance. Trust your inner wisdom - it's your cosmic compass guiding you forward."
            ]
            return energyResponses.randomElement() ?? energyResponses[0]
        }
        
        // Default cosmic responses
        let generalResponses = [
            "✨ The starlight reveals that you're entering a powerful phase of growth and transformation. The universe is conspiring to support your highest good.",
            "🌟 Your cosmic blueprint shows incredible potential waiting to unfold. Trust the journey and embrace the magical synchronicities coming your way.",
            "💫 The celestial energies surrounding you pulse with infinite possibility. You're being guided toward your true purpose - can you feel it?",
            "🔮 The cosmic web connects all things, and right now, it's weaving beautiful opportunities into your reality. Stay open to the magic around you.",
            "🌙 Your soul's journey is written in the stars, and this moment is a crucial chapter. The universe is whispering guidance - listen with your heart."
        ]
        return generalResponses.randomElement() ?? generalResponses[0]
    }
}

// MARK: - Cosmic Chat Models

struct CosmicMessage: Identifiable {
    let id: String
    let text: String
    let isUser: Bool
    let messageType: CosmicMessageType
    let timestamp: Date
}

enum CosmicMessageType {
    case welcome
    case question
    case insight
    case guidance
    case prediction
    
    var backgroundColor: [Color] {
        switch self {
        case .welcome:
            return [.purple.opacity(0.3), .indigo.opacity(0.2)]
        case .question:
            return [.blue.opacity(0.3), .cyan.opacity(0.2)]
        case .insight:
            return [.orange.opacity(0.3), .yellow.opacity(0.2)]
        case .guidance:
            return [.green.opacity(0.3), .mint.opacity(0.2)]
        case .prediction:
            return [.pink.opacity(0.3), .purple.opacity(0.2)]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .welcome: return .purple
        case .question: return .blue
        case .insight: return .orange
        case .guidance: return .green
        case .prediction: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .welcome: return "sparkles"
        case .question: return "questionmark.circle"
        case .insight: return "star.fill"
        case .guidance: return "lightbulb.fill"
        case .prediction: return "crystal.ball"
        }
    }
}

// MARK: - Cosmic Chat Background

struct CosmicChatBackground: View {
    @Binding var animateStars: Bool
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    Color(.systemIndigo).opacity(0.1),
                    Color(.systemPurple).opacity(0.05),
                    Color(.systemBlue).opacity(0.03)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating stars
            ForEach(0..<12, id: \.self) { i in
                Image(systemName: ["star.fill", "sparkles", "star.circle.fill", "moon.stars.fill"].randomElement() ?? "star.fill")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundStyle(.white.opacity(Double.random(in: 0.1...0.3)))
                    .position(
                        x: CGFloat.random(in: 20...350),
                        y: CGFloat.random(in: 50...700)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.5),
                        value: animateStars
                    )
                    .offset(
                        x: animateStars ? CGFloat.random(in: -10...10) : 0,
                        y: animateStars ? CGFloat.random(in: -15...15) : 0
                    )
                    .opacity(animateStars ? Double.random(in: 0.2...0.6) : 0.1)
            }
        }
    }
}

// MARK: - Cosmic Message View

struct CosmicMessageView: View {
    let message: CosmicMessage
    @State private var animateMessage = false
    @State private var showTimestamp = false
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
                userMessageView
            } else {
                aiMessageView
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateMessage = true
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTimestamp.toggle()
            }
        }
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(message.text)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            
            if showTimestamp {
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(animateMessage ? 1 : 0.8)
        .opacity(animateMessage ? 1 : 0)
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // AI Avatar with cosmic effect
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: message.messageType.backgroundColor,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: message.messageType.icon)
                        .font(.title3)
                        .foregroundStyle(message.messageType.accentColor)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                }
                
                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.text)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(message.messageType.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: message.messageType.accentColor.opacity(0.2), radius: 6, y: 3)
                    
                    // Message type indicator
                    HStack(spacing: 4) {
                        Image(systemName: message.messageType.icon)
                            .font(.caption2)
                            .foregroundStyle(message.messageType.accentColor)
                        
                        Text(message.messageType.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            if showTimestamp {
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 52)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(animateMessage ? 1 : 0.8)
        .opacity(animateMessage ? 1 : 0)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension CosmicMessageType {
    var displayName: String {
        switch self {
        case .welcome: return "Welcome"
        case .question: return "Question"
        case .insight: return "Cosmic Insight"
        case .guidance: return "Divine Guidance"
        case .prediction: return "Celestial Prediction"
        }
    }
}

// MARK: - Cosmic Typing Indicator

struct CosmicTypingIndicator: View {
    @State private var animateDots = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .indigo.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeating)
            }
            
            // Typing animation
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("✨ The cosmos is aligning your answer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(.purple)
                                .frame(width: 4, height: 4)
                                .scaleEffect(animateDots ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: animateDots
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.purple.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .onAppear {
            animateDots = true
        }
    }
}

// MARK: - Cosmic Input Area

struct CosmicInputArea: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onQuickQuestion: (String) -> Void
    
    @State private var isInputFocused = false
    @FocusState private var textFieldFocused: Bool
    
    private let quickQuestions = [
        "What's my love forecast? 💖",
        "Career guidance? ⭐",
        "Today's energy? ☀️",
        "Mercury retrograde effects? ☿",
        "Best time for decisions? 🌙"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Questions Scroll
            if !isInputFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickQuestions, id: \.self) { question in
                            Button {
                                onQuickQuestion(question)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            } label: {
                                Text(question)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        .regularMaterial,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(.purple.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .purple.opacity(0.1), radius: 4, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: isInputFocused)
            }
            
            // Input Container
            HStack(spacing: 12) {
                // Text Input Field
                HStack {
                    TextField("Ask the cosmos anything...", text: $messageText, axis: .vertical)
                        .font(.callout)
                        .lineLimit(1...4)
                        .focused($textFieldFocused)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 25)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(isInputFocused ? .purple.opacity(0.5) : .gray.opacity(0.2), lineWidth: 1.5)
                        )
                        .shadow(color: isInputFocused ? .purple.opacity(0.2) : .clear, radius: 8, y: 4)
                }
                
                // Send Button
                Button(action: {
                    onSend()
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: messageText.isEmpty ? [.gray.opacity(0.3)] : [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: messageText.isEmpty ? .clear : .purple.opacity(0.4), radius: 8, y: 4)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(45))
                    }
                }
                .disabled(messageText.isEmpty)
                .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(.ultraThinMaterial)
            .onChange(of: textFieldFocused) { _, focused in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInputFocused = focused
                }
            }
        }
    }
}

struct ProfileTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var bookmarkedReadings: [BookmarkedReading] = []
    
    private let tabs = ["Overview", "Birth Chart", "Daily", "Saved"]
    
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
                        ProfileOverviewView()
                            .environmentObject(auth)
                    case 1:
                        InteractiveChartsView(
                            selectedDate: selectedDate
                        )
                    case 2:
                        CalendarHoroscopeView(
                            selectedDate: $selectedDate,
                            onBookmark: bookmarkReading
                        )
                    case 3:
                        BookmarkedReadingsView(
                            bookmarks: bookmarkedReadings,
                            onRemove: removeBookmark
                        )
                    default:
                        ProfileOverviewView()
                            .environmentObject(auth)
                    }
                }
            }
            .navigationTitle("Profile")
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
            EnhancedSettingsView(auth: auth)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToProfileSection)) { notification in
            if let sectionIndex = notification.object as? Int {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = sectionIndex
                }
            }
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

// MARK: - Profile Overview View

struct ProfileOverviewView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header with Quick Actions
                VStack(spacing: 16) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.purple, .blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        
                        Text(auth.profileManager.profile.fullName.prefix(2).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text(auth.profileManager.profile.fullName.isEmpty ? "Your Name" : auth.profileManager.profile.fullName)
                            .font(.title2.weight(.semibold))
                        
                        if let sunSign = auth.profileManager.profile.sunSign {
                            Text(sunSign)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Edit Profile") {
                            showingEditSheet = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.top)
                
                // Quick Insights Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    QuickInsightCard(
                        title: "Sun Sign",
                        value: auth.profileManager.profile.sunSign ?? "Unknown",
                        icon: "sun.max.fill",
                        color: .orange
                    )
                    
                    QuickInsightCard(
                        title: "Moon Sign", 
                        value: auth.profileManager.profile.moonSign ?? "Calculate",
                        icon: "moon.stars.fill",
                        color: .blue
                    )
                    
                    QuickInsightCard(
                        title: "Rising Sign",
                        value: auth.profileManager.profile.risingSign ?? "Calculate", 
                        icon: "sunrise.fill",
                        color: .pink
                    )
                    
                    QuickInsightCard(
                        title: "Birth Place",
                        value: auth.profileManager.profile.birthPlace ?? "Not Set",
                        icon: "location.fill",
                        color: .green
                    )
                }
                
                // Recent Activity or Next Steps
                VStack(spacing: 0) {
                    HStack {
                        Text("Your Astrological Journey")
                            .font(.headline.weight(.semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    VStack(spacing: 12) {
                        NavigationRowView(
                            title: "Complete Birth Chart",
                            subtitle: "Calculate your full astrological profile",
                            icon: "chart.pie.fill",
                            action: { /* Navigate to birth chart */ }
                        )
                        
                        NavigationRowView(
                            title: "Today's Horoscope",
                            subtitle: "See what the stars have in store",
                            icon: "calendar.circle.fill",
                            action: { /* Navigate to daily */ }
                        )
                        
                        NavigationRowView(
                            title: "Compatibility Check",
                            subtitle: "Compare with friends and partners",
                            icon: "heart.circle.fill",
                            action: { /* Navigate to compatibility */ }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.secondary.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingEditSheet) {
            ProfileEditView()
                .environmentObject(auth)
        }
    }
}

struct QuickInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct NavigationRowView: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var isEditing = false
    @State private var editedProfile: UserProfile = UserProfile()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.purple, .blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        
                        Text(auth.profileManager.profile.fullName.prefix(2).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text(auth.profileManager.profile.fullName.isEmpty ? "Your Name" : auth.profileManager.profile.fullName)
                            .font(.title2.weight(.semibold))
                        
                        if let sunSign = auth.profileManager.profile.sunSign {
                            Text(sunSign)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top)
                
                // Birth Information Card
                VStack(spacing: 0) {
                    HStack {
                        Text("Birth Information")
                            .font(.headline.weight(.semibold))
                        Spacer()
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                auth.profileManager.updateProfile(editedProfile)
                            } else {
                                editedProfile = auth.profileManager.profile
                            }
                            isEditing.toggle()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    if isEditing {
                        VStack(spacing: 16) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                TextField("Enter your full name", text: $editedProfile.fullName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Birth Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Date")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                DatePicker("Birth Date", selection: $editedProfile.birthDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            }
                            
                            // Birth Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Time")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                DatePicker("Birth Time", selection: Binding(
                                    get: { editedProfile.birthTime ?? Date() },
                                    set: { editedProfile.birthTime = $0 }
                                ), displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                            }
                            
                            // Birth Place
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Place")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                TextField("City, State/Country", text: Binding(
                                    get: { editedProfile.birthPlace ?? "" },
                                    set: { editedProfile.birthPlace = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        VStack(spacing: 12) {
                            ProfileInfoRow(
                                title: "Birth Date",
                                value: formatDate(auth.profileManager.profile.birthDate)
                            )
                            
                            ProfileInfoRow(
                                title: "Birth Time",
                                value: auth.profileManager.profile.birthTime.map(formatTime) ?? "Not set"
                            )
                            
                            ProfileInfoRow(
                                title: "Birth Place",
                                value: auth.profileManager.profile.birthPlace ?? "Not set"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.secondary.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Astrological Signs Card
                VStack(spacing: 0) {
                    HStack {
                        Text("Astrological Signs")
                            .font(.headline.weight(.semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    VStack(spacing: 12) {
                        ProfileInfoRow(
                            title: "Sun Sign",
                            value: auth.profileManager.profile.sunSign ?? "Calculate from birth info"
                        )
                        
                        ProfileInfoRow(
                            title: "Moon Sign",
                            value: auth.profileManager.profile.moonSign ?? "Requires birth time & place"
                        )
                        
                        ProfileInfoRow(
                            title: "Rising Sign",
                            value: auth.profileManager.profile.risingSign ?? "Requires birth time & place"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.secondary.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            editedProfile = auth.profileManager.profile
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Enhanced Settings View

struct EnhancedSettingsView: View {
    @ObservedObject var auth: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountDeletion = false
    @State private var notificationsEnabled = true
    @State private var dailyReminder = true
    @State private var weeklyReport = false
    @State private var selectedTheme = "Auto"
    
    private let themes = ["Auto", "Light", "Dark"]
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    ProfileSettingsRow(auth: auth)
                } header: {
                    Text("Profile")
                }
                
                // App Preferences
                Section {
                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    if notificationsEnabled {
                        HStack {
                            Label("Daily Horoscope", systemImage: "sun.max.fill")
                            Spacer()
                            Toggle("", isOn: $dailyReminder)
                        }
                        
                        HStack {
                            Label("Weekly Report", systemImage: "calendar.badge.clock")
                            Spacer()
                            Toggle("", isOn: $weeklyReport)
                        }
                    }
                    
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
                        Spacer()
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(themes, id: \.self) { theme in
                                Text(theme).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Data & Privacy
                Section {
                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        Label("Data & Privacy", systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink {
                        ExportDataView(auth: auth)
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up.fill")
                    }
                } header: {
                    Text("Data & Privacy")
                }
                
                // Support
                Section {
                    Link(destination: URL(string: "mailto:support@astronova.app")!) {
                        Label("Contact Support", systemImage: "questionmark.circle.fill")
                    }
                    
                    Link(destination: URL(string: "https://astronova.app/help")!) {
                        Label("Help Center", systemImage: "book.fill")
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle.fill")
                    }
                } header: {
                    Text("Support")
                }
                
                // Account Actions
                Section {
                    Button {
                        auth.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right.fill")
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        showingAccountDeletion = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Delete Account", isPresented: $showingAccountDeletion) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle account deletion
                auth.signOut()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

struct ProfileSettingsRow: View {
    @ObservedObject var auth: AuthState
    @State private var showingEditProfile = false
    
    var body: some View {
        Button {
            showingEditProfile = true
        } label: {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(auth.profileManager.profile.fullName.prefix(2).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.profileManager.profile.fullName.isEmpty ? "Set up profile" : auth.profileManager.profile.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(auth.profileManager.profile.birthPlace ?? "Add birth details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditView()
                .environmentObject(auth)
        }
    }
}

struct DataPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("We take your privacy seriously. Here's how we handle your data:")
                    .font(.body)
                
                PrivacySection(
                    title: "What We Collect",
                    content: "• Birth date, time, and location\n• Astrological preferences\n• App usage analytics"
                )
                
                PrivacySection(
                    title: "How We Use It",
                    content: "• Generate personalized horoscopes\n• Calculate astrological charts\n• Improve app experience"
                )
                
                PrivacySection(
                    title: "Data Security",
                    content: "• All data is encrypted\n• Stored securely on your device\n• Optional cloud backup via iCloud"
                )
            }
            .padding()
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

struct ExportDataView: View {
    @ObservedObject var auth: AuthState
    @State private var showingShareSheet = false
    @State private var exportData: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Export Your Data")
                    .font(.title2.weight(.semibold))
                
                Text("Download all your astrological data including birth information, preferences, and saved readings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Export Data") {
                generateExportData()
                showingShareSheet = true
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [exportData])
        }
    }
    
    private func generateExportData() {
        let profile = auth.profileManager.profile
        
        // Create JSON format for better structure and safety
        let exportDict: [String: Any] = [
            "app": "Astronova",
            "version": "1.0.0",
            "exportDate": Date().ISO8601Format(),
            "profile": [
                "fullName": profile.fullName,
                "birthDate": profile.birthDate.ISO8601Format(),
                "birthTime": profile.birthTime?.ISO8601Format() ?? "",
                "birthPlace": profile.birthPlace ?? "",
                "sunSign": profile.sunSign ?? "",
                "moonSign": profile.moonSign ?? "",
                "risingSign": profile.risingSign ?? ""
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                exportData = jsonString
            } else {
                exportData = "Error: Could not convert export data to string"
            }
        } catch {
            exportData = "Error generating export data: \(error.localizedDescription)"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                
                VStack(spacing: 8) {
                    Text("Astronova")
                        .font(.title.weight(.bold))
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text("Discover what the stars reveal about your personality, relationships, and destiny through personalized cosmic insights.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Link("Privacy Policy", destination: URL(string: "https://astronova.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://astronova.app/terms")!)
                    Link("Acknowledgments", destination: URL(string: "https://astronova.app/acknowledgments")!)
                }
                .font(.subheadline)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Calendar Horoscope View

struct CalendarHoroscopeView: View {
    @Binding var selectedDate: Date
    let onBookmark: (HoroscopeReading) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Horizontal Date Selector
                HorizontalDateSelector(selectedDate: $selectedDate)
                
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
    }
}

struct HorizontalDateSelector: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var currentWeekDates: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let offsetWeek = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: startOfWeek) ?? startOfWeek
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: offsetWeek)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header with Navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentWeekOffset -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentWeekOffset += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }
            
            // Horizontal Date Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        DateCard(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DateCard: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var dayNumber: String {
        Calendar.current.component(.day, from: date).description
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(dayFormatter.string(from: date))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                
                Text(dayNumber)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 50, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday && !isSelected ? .blue : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

// MARK: - Tab Guide Overlay

struct TabGuideOverlay: View {
    let step: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var animateContent = false
    
    private let guides = [
        TabGuideContent(
            title: "Welcome to Today",
            description: "Your daily cosmic insights and personalized guidance start here. Check your horoscope, lucky elements, and planetary influences.",
            icon: "sun.and.horizon.circle.fill",
            color: .orange
        ),
        TabGuideContent(
            title: "Connect with Friends",
            description: "Discover compatibility with friends, family, or that special someone. Explore cosmic connections and relationships.",
            icon: "heart.circle.fill",
            color: .pink
        ),
        TabGuideContent(
            title: "Enter the Cosmic Nexus",
            description: "Chat with your AI astrologer for personalized insights about love, career, and life decisions in a beautiful cosmic interface.",
            icon: "brain.head.profile",
            color: .blue
        ),
        TabGuideContent(
            title: "Your Cosmic Essence",
            description: "Explore birth charts, save favorite readings, and track your spiritual journey through the stars over time.",
            icon: "person.crop.circle.badge.moon",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Rectangle()
                .fill(.black.opacity(0.4))
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Guide content card
                VStack(spacing: 24) {
                    // Icon and title
                    VStack(spacing: 16) {
                        Image(systemName: guides[step].icon)
                            .font(.system(size: 50))
                            .foregroundStyle(guides[step].color)
                            .scaleEffect(animateContent ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateContent)
                        
                        VStack(spacing: 8) {
                            Text(guides[step].title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text(guides[step].description)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    // Step indicator
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index <= step ? guides[step].color : .gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == step ? 1.3 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: step)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: onNext) {
                            HStack {
                                if step == 3 {
                                    Text("Start Your Journey")
                                        .font(.headline.weight(.semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                } else {
                                    Text("Next")
                                        .font(.headline.weight(.semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.title3)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(guides[step].color, in: RoundedRectangle(cornerRadius: 25))
                            .shadow(color: guides[step].color.opacity(0.3), radius: 8, y: 4)
                        }
                        
                        Button("Skip Tour", action: onSkip)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
}

struct TabGuideContent {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
}