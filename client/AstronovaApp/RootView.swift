import SwiftUI
import Contacts
import ContactsUI
import Combine
import StoreKit
import AuthenticationServices
import CoreLocation
import MapKit

// MARK: - Temporary Stubs for Missing Components

struct ProfileSetupContentView: View {
    @EnvironmentObject private var auth: AuthState
    @Binding var currentStep: Int
    @Binding var fullName: String
    @Binding var birthDate: Date
    @Binding var birthTime: Date
    @Binding var birthPlace: String
    @Binding var showingPersonalizedInsight: Bool
    @Binding var personalizedInsight: String
    
    let handleQuickStart: () -> Void
    let handleContinue: () -> Void
    let canContinue: Bool
    let totalSteps: Int
    let showPersonalizedInsight: () -> Void

    var body: some View {
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
                                .scaleEffect(step == currentStep ? 1.3 : 1.0)
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
                EnhancedBirthDateStepView(birthDate: $birthDate, onQuickStart: handleQuickStart)
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
            
            if !showingPersonalizedInsight {
                // Beautiful action button
                VStack(spacing: 16) {
                    Button {
                        handleContinue()
                    } label: {
                        HStack {
                            if currentStep == totalSteps - 1 {
                                Image(systemName: "moon.stars.circle.fill")
                                    .font(.title3.weight(.semibold))
                                Text("Create My Profile")
                                    .font(.title3.weight(.semibold))
                            } else {
                                let buttonText = currentStep == 0 ? "Begin Journey" : 
                                                currentStep == 4 ? (birthPlace.isEmpty ? "Skip for Now" : "Continue") : 
                                                "Continue"
                                Text(buttonText)
                                    .font(.title3.weight(.semibold))
                                Image(systemName: currentStep == 4 && birthPlace.isEmpty ? "forward.end" : "arrow.right")
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
}

// StoreKitManager is implemented as a full StoreKit 2 manager in StoreKitManager.swift

// MARK: - Profile Setup Components

struct AnimatedCosmicBackground: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
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
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateGradient)
    }
}

struct FloatingStarsView: View {
    @Binding var animateStars: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        let count = reduceMotion ? 0 : 6
        ForEach(0..<count, id: \.self) { i in
            Image(systemName: ["star.fill", "sparkles", "star.circle.fill"].randomElement()!)
                .font(.system(size: CGFloat.random(in: 12...24)))
                .foregroundStyle(.white.opacity(0.3))
                .position(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...600)
                )
                .offset(y: animateStars ? -12 : 12)
                .animation(!reduceMotion ? .easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true).delay(Double(i) * 0.2) : nil, value: animateStars)
        }
    }
}

struct PersonalizedInsightOverlay: View {
    @Binding var showingPersonalizedInsight: Bool
    @Binding var showingConfetti: Bool
    let fullName: String
    let personalizedInsight: String
    let clearProfileSetupProgress: () -> Void
    let completeProfileSetup: () -> Void
    
    var body: some View {
        Group {
            if showingPersonalizedInsight {
                PersonalizedInsightView(
                    name: fullName,
                    insight: personalizedInsight,
                    onContinue: {
                        clearProfileSetupProgress()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showingPersonalizedInsight = false
                            showingConfetti = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            completeProfileSetup()
                        }
                    }
                )
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Pricing Models

struct ReportPricing {
    let id: String
    let title: String
    let price: String
    let localizedPrice: String?
    let description: String
    
    static let loveReport = ReportPricing(
        id: "love_forecast",
        title: "Love Forecast",
        price: "$4.99",
        localizedPrice: nil,
        description: "Romantic timing & compatibility"
    )
    
    static let birthChart = ReportPricing(
        id: "birth_chart",
        title: "Birth Chart Reading",
        price: "$7.99",
        localizedPrice: nil,
        description: "Complete personality analysis"
    )
    
    static let careerForecast = ReportPricing(
        id: "career_forecast",
        title: "Career Forecast", 
        price: "$5.99",
        localizedPrice: nil,
        description: "Professional guidance & timing"
    )
    
    static let yearAhead = ReportPricing(
        id: "year_ahead",
        title: "Year Ahead",
        price: "$9.99",
        localizedPrice: nil,
        description: "12-month cosmic roadmap"
    )
    
    static let allReports = [loveReport, birthChart, careerForecast, yearAhead]
    
    static func pricing(for reportType: String) -> ReportPricing? {
        return allReports.first { $0.id == reportType }
    }
}

// MARK: - Notification.Name Helpers


/// Decides which high-level screen to show based on authentication state.
struct RootView: View {
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                LoadingView()
            case .signedOut:
                CompellingLandingView()
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("profile_setup_step") private var currentStep = 0
    @AppStorage("profile_setup_name") private var fullName = ""
    @AppStorage("profile_setup_birth_date") private var birthDateTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("profile_setup_birth_time") private var birthTimeTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("profile_setup_birth_place") private var birthPlace = ""
    @State private var showingPersonalizedInsight = false
    @State private var showingConfetti = false
    @State private var personalizedInsight = ""
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    // Computed properties for date binding
    private var birthDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthDateTimestamp) },
            set: { birthDateTimestamp = $0.timeIntervalSince1970 }
        )
    }
    
    private var birthTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthTimeTimestamp) },
            set: { birthTimeTimestamp = $0.timeIntervalSince1970 }
        )
    }
    
    private let totalSteps = 5
    
    private var completionPercentage: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        ZStack {
            AnimatedCosmicBackground(animateGradient: $animateGradient)
            
            FloatingStarsView(animateStars: $animateStars)
            
            ProfileSetupContentView(
                currentStep: $currentStep,
                fullName: $fullName,
                birthDate: birthDate,
                birthTime: birthTime,
                birthPlace: $birthPlace,
                showingPersonalizedInsight: $showingPersonalizedInsight,
                personalizedInsight: $personalizedInsight,
                handleQuickStart: handleQuickStart,
                handleContinue: handleContinue,
                canContinue: canContinue,
                totalSteps: totalSteps,
                showPersonalizedInsight: showPersonalizedInsight
            )
        }
        .overlay(personalizedInsightOverlay)
        .overlay(confettiOverlay)
        .onAppear(perform: setupAnimations)
    }
    
    @ViewBuilder
    private var personalizedInsightOverlay: some View {
        PersonalizedInsightOverlay(
            showingPersonalizedInsight: $showingPersonalizedInsight,
            showingConfetti: $showingConfetti,
            fullName: fullName,
            personalizedInsight: personalizedInsight,
            clearProfileSetupProgress: clearProfileSetupProgress,
            completeProfileSetup: { auth.completeProfileSetup() }
        )
    }
    
    @ViewBuilder
    private var confettiOverlay: some View {
        ConfettiView(isActive: $showingConfetti)
            .allowsHitTesting(false)
    }
    
    private func setupAnimations() {
        let lean = true // default to lean onboarding for speed
        if !lean && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.3).delay(0.4)) {
                animateGradient = true
                animateStars = true
            }
        } else {
            animateGradient = false
            animateStars = false
        }
        restoreProfileProgress()
        if currentStep == 0 { currentStep = 2 }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case 0: return true
        case 1: return isValidName(fullName)
        case 2: return isValidBirthDate(birthDate.wrappedValue)
        case 3: return true // Birth time is optional but always valid
        case 4: return true // Birth place is optional - can skip or provide
        default: return false
        }
    }
    
    private func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && 
               trimmedName.count <= 50 && 
               !trimmedName.contains("  ") &&
               trimmedName.range(of: "^[a-zA-Z\\s\\-']+$", options: .regularExpression) != nil
    }
    
    private func isValidBirthDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if date is in the future
        if date > now {
            return false
        }
        
        // Check if date is too far in the past (more than 120 years ago)
        if let earliestValidDate = calendar.date(byAdding: .year, value: -120, to: now),
           date < earliestValidDate {
            return false
        }
        
        return true
    }
    
    private func isValidLocation() -> Bool {
        // Check if we have valid coordinates from the location selection
        return auth.profileManager.profile.birthCoordinates != nil &&
               auth.profileManager.profile.timezone != nil
    }
    
    private func handleQuickStart() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save minimal profile data (name and birth date)
        auth.profileManager.profile.fullName = fullName
        auth.profileManager.profile.birthDate = birthDate.wrappedValue
        
        // Mark as quick start user
        auth.startQuickStart()
        
        // Try to save the profile
        do {
            try auth.profileManager.saveProfile()
        } catch {
            print("Failed to save quick start profile: \(error)")
        }
        
        // Clear persisted setup data since we're done
        clearProfileSetupProgress()
        
        // Generate instant insight with just birth date
        personalizedInsight = generateQuickStartInsight()
        showPersonalizedInsight()
    }
    
    private func handleContinue() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if currentStep == totalSteps - 1 {
            // Generate personalized insight
            generatePersonalizedInsight()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentStep = min(totalSteps - 1, currentStep + 1)
            }
        }
    }
    
    private func generatePersonalizedInsight() {
        // Save the profile data with error handling
        auth.profileManager.profile.fullName = fullName
        auth.profileManager.profile.birthDate = birthDate.wrappedValue
        auth.profileManager.profile.birthTime = birthTime.wrappedValue
        auth.profileManager.profile.birthPlace = birthPlace
        
        // For birth place, search for coordinates and timezone only if provided
        Task {
            if !birthPlace.isEmpty {
                // Search for location coordinates and timezone
                let locations = await auth.profileManager.searchLocations(query: birthPlace)
                if !locations.isEmpty, let location = locations.first {
                    await MainActor.run {
                        auth.profileManager.setBirthLocation(location)
                    }
                } else {
                    print("No location found for: \(birthPlace)")
                }
            } else {
                print("Birth place skipped - user can add later")
            }
            
            // Attempt to save the profile with error handling
            do {
                try auth.profileManager.saveProfile()
            } catch {
                await MainActor.run {
                    saveError = "Failed to save profile: \(error.localizedDescription)"
                    showingSaveError = true
                }
                print("Profile save error: \(error)")
            }
            
            // Generate real astrological insight using API
            if auth.isAPIConnected {
                await generateRealAstrologicalInsight()
            } else {
                print("API not connected, generating offline insight")
                await generateOfflineInsight()
            }
        }
    }
    
    private func generateRealAstrologicalInsight() async {
        // Generate chart and get real astrological data
        await auth.profileManager.generateChart()
        
        if let chart = auth.profileManager.lastChart,
           let westernChart = chart.westernChart {
            
            let sunSign = westernChart.positions["sun"]?.sign ?? "Unknown"
            let moonSign = westernChart.positions["moon"]?.sign ?? "Unknown"
            
            let locationText = birthPlace.isEmpty ? "" : " in \(birthPlace)"
            
            let insight = """
            Welcome to your cosmic journey, \(fullName)! 
            
            Born on \(formatDate(birthDate.wrappedValue)) at \(formatTime(birthTime.wrappedValue))\(locationText), the stars reveal fascinating insights about your celestial blueprint.
            
            Your Sun in \(sunSign) illuminates your core identity, while your Moon in \(moonSign) reflects your emotional nature. This unique combination creates a personality that is both dynamic and deeply intuitive.
            
            The planetary positions at your birth moment suggest you possess natural talents for leadership and creativity, with a special gift for understanding others' perspectives.
            """
            
            await MainActor.run {
                personalizedInsight = insight
                showPersonalizedInsight()
            }
        } else {
            await generateOfflineInsight()
        }
    }
    
    private func generateOfflineInsight() async {
        let locationText = birthPlace.isEmpty ? "" : " in \(birthPlace)"
        
        let fallbackInsights = [
            "Your birth on \(formatDate(birthDate.wrappedValue)) at \(formatTime(birthTime.wrappedValue))\(locationText) reveals a powerful cosmic alignment. The stars suggest you have natural leadership qualities and a deep connection to creative energies.",
            "Born under the influence of \(formatDate(birthDate.wrappedValue))\(locationText), you carry the gift of intuition and emotional wisdom. The universe has blessed you with the ability to inspire others.",
            "The celestial patterns on \(formatDate(birthDate.wrappedValue)) at \(formatTime(birthTime.wrappedValue)) indicate a soul destined for transformation and growth. Your journey is one of continuous evolution and self-discovery."
        ]
        
        await MainActor.run {
            personalizedInsight = fallbackInsights.randomElement() ?? fallbackInsights[0]
            showPersonalizedInsight()
        }
    }
    
    private func clearProfileSetupProgress() {
        currentStep = 0
        fullName = ""
        birthDateTimestamp = Date().timeIntervalSince1970
        birthTimeTimestamp = Date().timeIntervalSince1970
        birthPlace = ""
    }
    
    private func restoreProfileProgress() {
        // If we have saved profile data, populate the profile manager
        if !fullName.isEmpty || currentStep > 0 {
            auth.profileManager.profile.fullName = fullName
            auth.profileManager.profile.birthDate = birthDate.wrappedValue
            auth.profileManager.profile.birthTime = birthTime.wrappedValue
            auth.profileManager.profile.birthPlace = birthPlace
        }
    }
    
    private func generateQuickStartInsight() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let birthDateString = dateFormatter.string(from: birthDate.wrappedValue)
        
        let quickStartInsights = [
            "Born on \(birthDateString), you're ready to explore the cosmos! Your sun sign reveals natural talents waiting to be discovered. Let's begin your astrological journey!",
            "Welcome to AstroNova! Your birth date of \(birthDateString) holds the key to understanding your cosmic blueprint. Ready to unlock your potential?",
            "The universe has been waiting for this moment! Born on \(birthDateString), you carry unique celestial gifts. Let's explore what the stars have in store for you."
        ]
        
        return quickStartInsights.randomElement() ?? quickStartInsights[0]
    }
    
    private func showPersonalizedInsight() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.3)) {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                    
                    Group {
                        if !reduceMotion {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(.white)
                                .symbolEffect(.variableColor, options: .repeating)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .animation(!reduceMotion ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: animateIcon)
                
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
        .onAppear { animateIcon = true }
    }
}

struct EnhancedNameStepView: View {
    @Binding var fullName: String
    @State private var animateIcon = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var validationError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                    
                    Group {
                        if !reduceMotion {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .animation(!reduceMotion ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: animateIcon)
                
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
                
                // Enhanced text field with validation
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
                                        .stroke(
                                            validationError != nil ? .red.opacity(0.6) : .white.opacity(0.3), 
                                            lineWidth: validationError != nil ? 2 : 1
                                        )
                                )
                        )
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onChange(of: fullName) { _, newValue in
                            validateName(newValue)
                        }
                    
                    // Validation feedback
                    if let error = validationError {
                        HStack {
                            Image(systemName: "exclamationmark.diamond.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else if !fullName.isEmpty && isValidName(fullName) {
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
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear { animateIcon = true }
    }
    
    private func hideKeyboard() {
        isTextFieldFocused = false
    }
    
    private func validateName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationError = nil
            return
        }
        
        if trimmedName.count < 2 {
            validationError = "Name must be at least 2 characters long"
            return
        }
        
        if trimmedName.count > 50 {
            validationError = "Name cannot exceed 50 characters"
            return
        }
        
        // Check for valid characters (letters, spaces, hyphens, apostrophes)
        let validNameRegex = "^[a-zA-Z\\s\\-']+$"
        let nameTest = NSPredicate(format: "SELF MATCHES %@", validNameRegex)
        if !nameTest.evaluate(with: trimmedName) {
            validationError = "Name can only contain letters, spaces, hyphens, and apostrophes"
            return
        }
        
        // Check for reasonable number of consecutive spaces
        if trimmedName.contains("  ") {
            validationError = "Name cannot contain multiple consecutive spaces"
            return
        }
        
        validationError = nil
    }
    
    private func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && 
               trimmedName.count <= 50 && 
               !trimmedName.contains("  ") &&
               trimmedName.range(of: "^[a-zA-Z\\s\\-']+$", options: .regularExpression) != nil
    }
}

struct EnhancedBirthDateStepView: View {
    @Binding var birthDate: Date
    @State private var animateIcon = false
    @State private var validationError: String?
    let onQuickStart: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                    
                    Group {
                        if !reduceMotion {
                            Image(systemName: "calendar")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating)
                        } else {
                            Image(systemName: "calendar")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .animation(!reduceMotion ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: animateIcon)
                
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
                
                // Enhanced date picker with validation
                VStack(spacing: 12) {
                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: getDateRange(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        validationError != nil ? .red.opacity(0.6) : .clear, 
                                        lineWidth: 2
                                    )
                            )
                    )
                    .colorScheme(.dark)
                    .padding(.horizontal, 24)
                    .onChange(of: birthDate) { _, newValue in
                        validateBirthDate(newValue)
                    }
                    
                    // Validation feedback
                    if let error = validationError {
                        HStack {
                            Image(systemName: "exclamationmark.diamond.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.horizontal, 24)
                    } else {
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
                
                // Quick Start option
                if validationError == nil {
                    VStack(spacing: 12) {
                        Divider()
                            .background(.white.opacity(0.3))
                            .padding(.horizontal, 24)
                        
                        Button {
                            onQuickStart?()
                        } label: {
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .font(.title3)
                                Text("Quick Start")
                                    .font(.title3.weight(.medium))
                                Spacer()
                                Text("Skip Details")
                                    .font(.caption.weight(.medium))
                                    .opacity(0.7)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Text("Start exploring with just your birth date. You can add birth time and location later for more precise readings.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: validationError == nil)
                }
            }
            
            Spacer()
        }
        .onAppear { animateIcon = true; validateBirthDate(birthDate) }
    }
    
    private func getDateRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let earliestDate = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date()
        let latestDate = Date()
        return earliestDate...latestDate
    }
    
    private func validateBirthDate(_ date: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if date is in the future
        if date > now {
            validationError = "Birth date cannot be in the future"
            return
        }
        
        // Check if date is too far in the past (more than 120 years ago)
        if let earliestValidDate = calendar.date(byAdding: .year, value: -120, to: now),
           date < earliestValidDate {
            validationError = "Birth date cannot be more than 120 years ago"
            return
        }
        
        validationError = nil
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
    @State private var unknownTime = false
    @State private var showWhy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

                    Group {
                        if !reduceMotion {
                            Image(systemName: "clock.badge.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating)
                        } else {
                            Image(systemName: "clock.badge.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .animation(!reduceMotion ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: animateIcon)

                VStack(spacing: 16) {
                    Text("What time were you born?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Birth time improves rising sign and house calculations. If unknown, we'll assume 12:00 noon and mark some insights as approximate.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }

                // Time picker with unknown toggle
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Toggle(isOn: $unknownTime) {
                            Text("I don't know my birth time")
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .tint(.white)

                        Button(action: { showWhy = true }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .alert("Why birth time matters", isPresented: $showWhy) {
                            Button("Got it", role: .cancel) {}
                        } message: {
                            Text("Birth time helps calculate your rising sign and houses. If you don't know it, we'll default to 12:00 noon, and some insights may be approximate.")
                        }
                    }

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
                    .disabled(unknownTime)
                    .opacity(unknownTime ? 0.5 : 1.0)

                    Text(unknownTime ? "We'll assume 12:00 noon (approximate)" : "Selected: \(formatSelectedTime())")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                        )
                        .onChange(of: unknownTime) { _, newValue in
                            if newValue {
                                // Set to noon to minimize bias when unknown
                                var comps = Calendar.current.dateComponents([.year,.month,.day], from: birthTime)
                                comps.hour = 12; comps.minute = 0
                                birthTime = Calendar.current.date(from: comps) ?? birthTime
                            }
                        }
                }
            }

            Spacer()
        }
        .onAppear { animateIcon = true }
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
    @State private var searchResults: [LocationResult] = []
    @State private var isSearching = false
    @State private var showDropdown = false
    @State private var searchTask: Task<Void, Never>?
    @EnvironmentObject private var auth: AuthState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                    
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                }
                .animation(!reduceMotion ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: animateIcon)
                
                VStack(spacing: 16) {
                    Text("Where were you born?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your birth location helps us calculate precise celestial positions. You can add this later if you prefer to skip for now.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
                
                // Enhanced text field with autocomplete
                VStack(spacing: 8) {
                    ZStack(alignment: .trailing) {
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
                            .onChange(of: birthPlace) { _, newValue in
                                handleLocationSearch(newValue)
                            }
                        
                        if isSearching {
                            ProgressView()
                                .foregroundStyle(.white)
                                .padding(.trailing, 20)
                        }
                    }
                    
                    // Location dropdown
                    if showDropdown && !searchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchResults.prefix(5), id: \.name) { location in
                                Button {
                                    selectLocation(location)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.name)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(.white)
                                            Text(location.fullName)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        Spacer()
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .background(.white.opacity(0.1))
                                
                                if location.name != searchResults.prefix(5).last?.name {
                                    Divider()
                                        .background(.white.opacity(0.2))
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if !birthPlace.isEmpty && !showDropdown {
                        HStack {
                            if auth.profileManager.profile.birthCoordinates != nil && auth.profileManager.profile.timezone != nil {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Perfect! Location validated with coordinates.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            } else {
                                Image(systemName: "exclamationmark.diamond.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Select a location from the dropdown for best results, or skip to add later.")
                                    .font(.caption)
                                    .foregroundStyle(.orange.opacity(0.9))
                            }
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: birthPlace.isEmpty)
                    }
                    
                    // Optional skip hint
                    if birthPlace.isEmpty && !showDropdown {
                        HStack {
                            Image(systemName: "questionmark.bubble.fill")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Birth location is optional - you can always add it later in your profile.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: birthPlace.isEmpty)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .onAppear { animateIcon = true }
        .onTapGesture {
            if showDropdown {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDropdown = false
                }
            }
        }
    }
    
    private func handleLocationSearch(_ query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, query.count >= 2 else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showDropdown = false
                searchResults = []
            }
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            if !Task.isCancelled {
                // Use MapKit for location search, fallback to existing API
                let results: [LocationResult]
                do {
                    results = try await MapKitLocationService.shared.searchPlaces(query: query)
                } catch {
                    print("MapKit search failed, using fallback: \(error)")
                    results = await auth.profileManager.searchLocations(query: query)
                }
                
                await MainActor.run {
                    if !Task.isCancelled {
                        searchResults = results
                        isSearching = false
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDropdown = !results.isEmpty
                        }
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ location: LocationResult) {
        birthPlace = location.fullName
        
        // Set location data in the profile manager
        auth.profileManager.setBirthLocation(location)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showDropdown = false
            isTextFieldFocused = false
        }
        
        searchResults = []
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Personalized Insight View

struct PersonalizedInsightView: View {
    let name: String
    let insight: String
    let onContinue: () -> Void
    @State private var animateElements = false
    @State private var showContent = false
    @State private var isAnalyzing = true
    @State private var scanProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Blurred cosmic background
            Rectangle()
                .fill(.black.opacity(0.4))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                Spacer()
                
                if isAnalyzing {
                    // Beautiful scanning animation
                    VStack(spacing: 32) {
                        // Cosmic scanner animation
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .blue.opacity(0.3), .cyan.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(pulseScale)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                            
                            // Inner cosmic symbol
                            Text("🌟")
                                .font(.system(size: 40))
                                .rotationEffect(.degrees(scanProgress * 360))
                                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: scanProgress)
                            
                            // Scanning line
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .cyan, .purple, .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 140, height: 2)
                                .offset(y: -60 + (scanProgress * 120))
                                .mask(Circle().frame(width: 120, height: 120))
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: scanProgress)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Analyzing Your Cosmic Blueprint")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Reading planetary positions and celestial influences...")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
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
                } else {
                    // Results view
                    VStack(spacing: 24) {
                        // Success header
                        VStack(spacing: 16) {
                            Text("✨")
                                .font(.system(size: 50))
                                .scaleEffect(showContent ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showContent)
                            
                            Text("Profile Created!")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                                .opacity(showContent ? 1 : 0)
                        }
                        
                        // Personalized content
                        VStack(spacing: 16) {
                            Text("Welcome, \(name.components(separatedBy: " ").first ?? name)!")
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
                                Text("Start Your Journey")
                                    .font(.headline.weight(.semibold))
                                Image(systemName: "arrow.forward.circle.fill")
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
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateElements = true
                pulseScale = 1.2
                scanProgress = 1.0
            }
            
            // Show analyzing phase for 3 seconds, then reveal results
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnalyzing = false
                }
                
                withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                    showContent = true
                }
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
        
        withAnimation(.easeOut(duration: 0.3)) {
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

// MARK: - Utilities

// Removed older InlineReportsShopView to avoid SKU drift; using InlineReportsStoreSheet everywhere.


// MARK: - Location Search Support

struct LocationSearchView: View {
    @Binding var query: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [String] = []
    
    var body: some View {
        NavigationStack {
            List(searchResults, id: \.self) { result in
                Button(result) {
                    query = result
                    dismiss()
                }
            }
            .searchable(text: $query, prompt: "Search for a city")
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
    @AppStorage("app_launch_count") private var appLaunchCount = 0
    @AppStorage("has_seen_tab_guide") private var hasSeenTabGuide = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Content area - extends full screen behind floating tab bar
            Group {
                switch selectedTab {
                case 0:
                    TodayTab()
                case 1:
                    FriendsTab()
                case 2:
                    TimeTravelTab()
                case 3:
                    NexusTab()
                case 4:
                    ProfileTab()
                default:
                    TodayTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom) // Allow content to extend behind tab bar
            
            // Floating Glassy Tab Bar - overlaid on top of content
            VStack {
                Spacer()
                if keyboardHeight == 0 {
                    FloatingTabBar(selectedTab: $selectedTab)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: keyboardHeight)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self.keyboardHeight = 0
            }
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
        .keyboardDismissButton()
    }
    
    private func trackAppLaunch() {
        appLaunchCount += 1
    }
    
    private func showFirstRunGuideIfNeeded() {
        if appLaunchCount <= 2 && !hasSeenTabGuide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showTabGuide = true
                }
            }
        }
    }
    
    private func dismissGuide() {
        withAnimation(.easeOut(duration: 0.3)) {
            showTabGuide = false
        }
        hasSeenTabGuide = true
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
            // Simple star/sparkle design representing AI magic
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
            // Don't set foregroundColor here - let it inherit from parent
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

struct TimeTravelTab: View {
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        NavigationStack {
            TimeTravelView()
                .environmentObject(auth)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(title: String, icon: String, customIcon: String?)] = [
        (title: "Discover", icon: "moon.stars.fill", customIcon: nil),
        (title: "Connect", icon: "person.2.square.stack.fill", customIcon: nil),
        (title: "Time Travel", icon: "clock", customIcon: nil),
        (title: "Ask", icon: "bubble.left.and.bubble.right.fill", customIcon: nil), 
        (title: "Manage", icon: "person.crop.circle.fill", customIcon: nil)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Icon with background
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue.gradient)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Icon
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: tabs[index].title == "Ask" ? 20 : 22, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(selectedTab == index ? .white : .secondary)
                        .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)
                        
                        // Title
                        Text(tabs[index].title)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundStyle(selectedTab == index ? .primary : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].title)
                .accessibilityHint("Tab \(index + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, max(4, 0)) // Use 0 instead of deprecated windows API
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
        .overlay(
            Rectangle()
                .fill(.separator.opacity(0.5))
                .frame(height: 0.5),
            alignment: .top
        )
        .ignoresSafeArea(.container, edges: .bottom)
    .clipShape(Rectangle())
    }
}

/// Floating, glassy, translucent tab bar that sits above content
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(title: String, icon: String, customIcon: String?)] = [
        (title: "Discover", icon: "moon.stars.fill", customIcon: nil),
        (title: "Connect", icon: "person.2.square.stack.fill", customIcon: nil),
        (title: "Time Travel", icon: "clock", customIcon: nil),
        (title: "Ask", icon: "bubble.left.and.bubble.right.fill", customIcon: nil), 
        (title: "Manage", icon: "person.crop.circle.fill", customIcon: nil)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        // Icon with modern floating design
                        ZStack {
                            // Background glow for selected tab
                            if selectedTab == index {
                                Circle()
                                    .fill(.blue.gradient)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .blue.opacity(0.25), radius: 6, x: 0, y: 2)
                                    .scaleEffect(1.1)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Icon
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 18, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .frame(width: 44, height: 32)
                        .foregroundStyle(selectedTab == index ? .white : .primary.opacity(0.7))
                        .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)
                        
                        // Title with fade effect
                        Text(tabs[index].title)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundStyle(selectedTab == index ? .primary : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .opacity(selectedTab == index ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].title)
                .accessibilityHint("Tab \(index + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            // Pure glass effect with minimal solid background
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial) // Pure material effect
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        )
        .overlay(
            // Subtle border glow with better transparency
            RoundedRectangle(cornerRadius: 25)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8) // Thinner and lower towards the edge
    }
}

// MARK: - Simple Tab Views

struct TodayTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingWelcome = false
    @State private var animateWelcome = false
    @State private var planetaryPositions: [PlanetaryPosition] = []
    @State private var showingReportSheet = false
    @State private var showingReportsLibrary = false
    @State private var selectedReportType: String = ""
    @State private var userReports: [DetailedReport] = []
    @State private var hasSubscription = false
    @State private var showingReportShop = false
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false
    
    private let apiServices = APIServices.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Today's date header
                    HStack {
                        Text("Today's Horoscope")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    todaysHoroscopeSection
                    
                    // Premium Insights Section (moved from Daily tab)
                    PremiumInsightsSection(
                        hasSubscription: hasSubscription,
                        onInsightTap: { reportType in
                            selectedReportType = reportType
                            showingReportSheet = true
                        },
                        onViewReports: {
                            showingReportsLibrary = true
                        },
                        savedReports: userReports
                    )

                    Button {
                        showingReportShop = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Explore all 7 detailed reports (from $12.99)")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    planetaryPositionsSection
                    
                    // Primary CTAs moved to bottom
                    PrimaryCTASection()
                    
                    Spacer(minLength: 120) // Extra padding for floating tab bar
                }
                .padding()
                .padding(.bottom, 120) // Ensure last content is visible above floating tab bar
            }
            .navigationTitle("Today")
        }
        .onAppear {
            if shouldShowWelcome {
                showingWelcome = true
                let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.6)
                let delayedAnimation = springAnimation.delay(0.5)
                withAnimation(delayedAnimation) {
                    animateWelcome = true
                }
            }
            planetaryPositions = []
            checkSubscriptionStatus()
            loadUserReports()
            if triggerShowReportShop {
                triggerShowReportShop = false
                showingReportShop = true
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportGenerationSheet(
                reportType: selectedReportType,
                onGenerate: generateReport,
                onDismiss: {
                    showingReportSheet = false
                }
            )
            .environmentObject(auth)
        }
        .sheet(isPresented: $showingReportsLibrary) {
            ReportsLibraryView(reports: userReports)
        }
        .sheet(isPresented: $showingReportShop) {
            InlineReportsStoreSheet().environmentObject(auth)
        }
    }
    
    @ViewBuilder
    private var todaysHoroscopeSection: some View {
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
            
            luckyElementsSection
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var keyThemesSection: some View {
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
    }
    
    @ViewBuilder
    private var luckyElementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Lucky Elements")
                .font(.headline)
            
            HStack(spacing: 32) {
                // Lucky Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lucky Color")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 3)
                            )
                        
                        Text("Purple")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.purple)
                    }
                }
                
                Spacer()
                
                // Lucky Number
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lucky Number")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Text("7")
                                .font(.body.weight(.bold))
                                .foregroundStyle(Color.primary)
                        }
                        
                        Text("Seven")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }
    
    @ViewBuilder
    private var planetaryPositionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Planetary Energies")
                .font(.headline)
            
            PlanetaryEnergiesView()
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkSubscriptionStatus() {
        hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }
    
    private func loadUserReports() {
        Task {
            do {
                // Use auth.userId once implemented or use a placeholder
                let reports = try await apiServices.getUserReports(userId: "current_user")
                await MainActor.run {
                    self.userReports = reports
                }
            } catch {
                print("Failed to load user reports: \(error)")
                await MainActor.run {
                    self.userReports = []
                }
            }
        }
    }
    
    private func generateReport(reportType: String) {
        Task {
            do {
                // Create birth data from auth user profile
                let birthData = BirthData(
                    name: auth.authenticatedUser?.fullName ?? "User",
                    date: "1990-01-01", // Placeholder - should come from user profile
                    time: "12:00",
                    latitude: 40.7128,
                    longitude: -74.0060,
                    city: "New York",
                    state: "NY",
                    country: "USA",
                    timezone: "America/New_York"
                )
                
                let _ = try await apiServices.generateReport(birthData: birthData, type: reportType)
                
                // Reload user reports after generation
                loadUserReports()
            } catch {
                print("Failed to generate report: \(error)")
            }
        }
    }
    
    private var shouldShowWelcome: Bool {
        return !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

struct PlanetaryEnergiesView: View {
    @State private var planetaryPositions: [DetailedPlanetaryPosition] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading planetary energies...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadPlanetaryData()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(planetaryPositions.prefix(5), id: \.id) { planet in
                        HStack {
                            Text(planet.symbol)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(planet.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(planet.sign) \(String(format: "%.1f", planet.degree))°")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if planet.retrograde {
                                Text("℞")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .onAppear {
            loadPlanetaryData()
        }
    }
    
    private func loadPlanetaryData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Primary: fetch via API (now with robust fallbacks inside APIServices)
                let positions = try await APIServices.shared.getDetailedPlanetaryPositions()
                await MainActor.run {
                    self.planetaryPositions = positions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to load planetary data"
                    self.isLoading = false
                }
            }
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
                    Image(systemName: "xmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                Text("💫")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Travel")
                        .font(.callout.weight(.medium))
                    Text("• Check daily insights below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Find compatibility matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Ask anything")
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
                        switchToTab(3) // Switch to NexusTab (Ask page)
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
                    title: "Time Travel Through Years",
                    description: "Dive deep into your cosmic blueprint and personality insights",
                    icon: "circle.grid.cross.fill",
                    color: .purple,
                    action: {
                        switchToTimeTravelTab()
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
        
        // Switch to Profile (Manage) tab and then to Charts section
        NotificationCenter.default.post(name: .switchToTab, object: 4)
        NotificationCenter.default.post(name: .switchToProfileSection, object: 1)
    }
    
    private func switchToTimeTravelTab() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        NotificationCenter.default.post(name: .switchToTab, object: 2)
    }

    private func switchToProfileBookmarks() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Switch to Profile (Manage) tab and then to Bookmarks section
        NotificationCenter.default.post(name: .switchToTab, object: 4)
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
    @EnvironmentObject private var auth: AuthState
    @State private var partnerName = ""
    @State private var partnerBirthDate = Date()
    @State private var showingResults = false
    @State private var showingContactsPicker = false
    @State private var animateHearts = false
    @State private var isCalculating = false
    @State private var compatibilityPercent: Int? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Compact modern header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                                .foregroundStyle(.pink)
                                .scaleEffect(animateHearts ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateHearts)
                            
                            Text("Compatibility Check")
                                .font(.title2.weight(.bold))
                            
                            Spacer()
                        }
                        
                        Text("Discover your cosmic connection")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Quick access from contacts
                    Button {
                        showingContactsPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.badge.gearshape.fill")
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
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.08))
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Manual input form
                    VStack(spacing: 16) {
                        HStack {
                            Text("Or enter details manually")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Name input with beautiful styling
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("Friend, family member, partner...", text: $partnerName)
                                    .font(.body)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
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
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
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
                                Task { await calculateCompatibility() }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.title3.weight(.semibold))
                                    Text(isCalculating ? "Analyzing…" : "Reveal Compatibility")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
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
                    if isCalculating {
                        ProgressView("Calculating compatibility…")
                            .padding()
                    }
                    
                    if showingResults {
                        VStack(spacing: 16) {
                            // Compatibility score with animation
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.rectangle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.pink)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Compatibility Score")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Based on cosmic alignment")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(compatibilityPercent ?? 75)%")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.green.opacity(0.08))
                                        .stroke(.green.opacity(0.2), lineWidth: 1)
                                )
                                
                                Text("Great cosmic connection! You and \(partnerName.isEmpty ? "this person" : partnerName) share harmonious energy patterns.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                    .padding(.horizontal, 4)
                            }
                            
                            // Compatibility breakdown
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                CompatibilityCard(title: "Emotional", score: 92, color: .purple)
                                CompatibilityCard(title: "Mental", score: 88, color: .blue)
                                CompatibilityCard(title: "Physical", score: 85, color: .pink)
                                CompatibilityCard(title: "Spiritual", score: 91, color: .green)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingResults)
                    }
                    
                    // Recent matches (simplified)
                    if !sampleMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
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
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(String(match.name.prefix(1)))
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(.blue)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(match.name)
                                            .font(.callout.weight(.medium))
                                        HStack(spacing: 4) {
                                            Text("☉ \(match.sun)")
                                            Text("☽ \(match.moon)")
                                            Text("⬆️ \(match.rising)")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
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
                .padding(.bottom, 120) // Additional bottom padding to show content behind floating tab bar
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
    
    private func calculateCompatibility() async {
        guard !isCalculating else { return }
        await MainActor.run {
            isCalculating = true
            showingResults = false
        }
        defer {
            Task { @MainActor in isCalculating = false }
        }
        do {
            // Build person1 (current user) from profile, falling back to minimal defaults
            let userProfile = auth.profileManager.profile
            let person1: BirthData
            if let _ = userProfile.birthTime,
               let _ = userProfile.timezone,
               let _ = userProfile.birthLatitude,
               let _ = userProfile.birthLongitude {
                person1 = try BirthData(from: userProfile)
            } else {
                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                person1 = BirthData(
                    name: userProfile.fullName.isEmpty ? "You" : userProfile.fullName,
                    date: df.string(from: userProfile.birthDate),
                    time: "12:00",
                    latitude: 0,
                    longitude: 0,
                    city: userProfile.birthPlace ?? "Unknown",
                    state: nil,
                    country: "Unknown",
                    timezone: "UTC"
                )
            }
            
            // Build partner from inputs (minimal viable defaults)
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let partner = BirthData(
                name: partnerName.isEmpty ? "Partner" : partnerName,
                date: df.string(from: partnerBirthDate),
                time: "12:00",
                latitude: 0,
                longitude: 0,
                city: "Unknown",
                state: nil,
                country: "Unknown",
                timezone: "UTC"
            )
            
            let response = try await APIServices.shared.getCompatibilityReport(person1: person1, person2: partner)
            let score = Int((response.compatibility_score * 100.0).rounded())
            await MainActor.run {
                compatibilityPercent = score
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingResults = true
                }
            }
        } catch {
            // Fallback to a neutral score on failure to avoid a dead-end UI
            await MainActor.run {
                compatibilityPercent = 75
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingResults = true
                }
            }
        }
    }
    
    private let sampleMatches = [
        (name: "Sarah", sun: "Leo", moon: "Pisces", rising: "Virgo"),
        (name: "Alex", sun: "Gemini", moon: "Scorpio", rising: "Libra"),
        (name: "Jordan", sun: "Aquarius", moon: "Taurus", rising: "Cancer")
    ]
}

struct CompatibilityCard: View {
    let title: String
    let score: Int
    let color: Color
    @State private var animateScore = false
    @State private var displayedScore = 0
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Text("\(displayedScore)%")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .scaleEffect(animateScore ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScore)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                displayedScore = score
                animateScore = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    animateScore = false
                }
            }
        }
    }
}

struct NexusTab: View {
    @State private var messageText = ""
    @State private var messages: [CosmicMessage] = [
        CosmicMessage(
            id: "welcome",
            text: "How can I help you this morning?",
            isUser: false,
            messageType: .welcome,
            timestamp: Date()
        )
    ]
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var showingTypingIndicator = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var dailyMessageCount = 0
    @State private var hasSubscription = false
    @State private var showingSubscriptionSheet = false
    @State private var showingChatPackages = false
    @State private var selectedModel = "zodiac"
    @State private var showingVoiceMode = false
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false
    
    @EnvironmentObject private var auth: AuthState
    private let apiServices = APIServices.shared
    private let freeMessageLimit = 5
    private let models = ["rashi", "zodiac", "loshu", "combined"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background for light/dark mode
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Message Limit Banner (for free users)
                    if !hasSubscription && dailyMessageCount >= freeMessageLimit && chatCredits == 0 {
                        MessageLimitBanner(
                            used: dailyMessageCount,
                            limit: freeMessageLimit,
                            onUpgrade: { showingSubscriptionSheet = true },
                            onBuyCredits: { showingChatPackages = true }
                        )
                    }
                    
                    // Chat messages
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(messages) { message in
                                CosmicMessageView(message: message)
                            }
                            
                            // Typing indicator
                            if showingTypingIndicator {
                                HStack {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color.gray.opacity(0.6))
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(showingTypingIndicator ? 1.0 : 0.5)
                                                .animation(
                                                    .easeInOut(duration: 0.6)
                                                        .repeatForever(autoreverses: true)
                                                        .delay(Double(index) * 0.2),
                                                    value: showingTypingIndicator
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            
                            // Error message
                            if let errorMessage = errorMessage {
                                ErrorMessageView(message: errorMessage) {
                                    self.errorMessage = nil
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    
                    Spacer()
                    
                    // Input area
                    CosmicInputArea(
                        messageText: $messageText,
                        onSend: sendMessage,
                        onQuickQuestion: { question in
                            messageText = question
                        }
                    )
                    .disabled(isLoading || (!hasSubscription && dailyMessageCount >= freeMessageLimit && chatCredits == 0))
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Model Picker
                    Menu {
                        ForEach(models, id: \.self) { model in
                            Button {
                                selectedModel = model
                            } label: {
                                HStack {
                                    Text(model.capitalized)
                                    if selectedModel == model {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedModel.capitalized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            animateStars = true
            loadMessageCount()
            checkSubscriptionStatus()
            if triggerShowChatPackages {
                triggerShowChatPackages = false
                showingChatPackages = true
            }
        }
        .sheet(isPresented: $showingSubscriptionSheet) { SubscriptionSheet() }
        .sheet(isPresented: $showingChatPackages) { InlineChatPackagesSheet() }
    }
    
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Check message limit for free users; allow credits to bypass
        if !hasSubscription && dailyMessageCount >= freeMessageLimit && chatCredits == 0 {
            errorMessage = "DAILY LIMIT REACHED"
            return
        }
        
        // Add user message
        let userMessage = CosmicMessage(
            id: UUID().uuidString,
            text: messageText,
            isUser: true,
            messageType: .question,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            messages.append(userMessage)
        }
        
        // Clear input and show typing indicator
        let currentMessage = messageText
        messageText = ""
        errorMessage = nil
        isLoading = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingTypingIndicator = true
        }
        
        Task {
            do {
                _ = ChatContext(
                    userChart: auth.profileManager.lastChart,
                    currentTransits: nil,
                    preferences: nil
                )
                
                let response = try await apiServices.sendChatMessage(currentMessage, context: "chat_context")
                
                await MainActor.run {
                    isLoading = false
                    
                    let aiMessage = CosmicMessage(
                        id: UUID().uuidString,
                        text: response.reply,
                        isUser: false,
                        messageType: .insight,
                        timestamp: Date()
                    )
                    
                    messages.append(aiMessage)
                    
                    // Increment counters: use credits first if out of free messages
                    if !hasSubscription {
                        if dailyMessageCount >= freeMessageLimit {
                            if chatCredits > 0 { chatCredits -= 1 }
                        } else {
                            dailyMessageCount += 1
                            saveMessageCount()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.errorMessage = "CONNECTION ERROR"
                }
            }
        }
    }
    
    private func loadMessageCount() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let key = "dailyMessageCount_\(today)"
        dailyMessageCount = UserDefaults.standard.integer(forKey: key)
    }
    
    private func saveMessageCount() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let key = "dailyMessageCount_\(today)"
        UserDefaults.standard.set(dailyMessageCount, forKey: key)
    }
    
    private func checkSubscriptionStatus() {
        hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }
}

// MARK: - Message Limit Banner

struct MessageLimitBanner: View {
    let used: Int
    let limit: Int
    let onUpgrade: () -> Void
    let onBuyCredits: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.circle.fill")
                .foregroundStyle(.orange)
            
            Text("\(used)/\(limit) free messages today")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if used >= limit {
                Button("Get Chat Packages") { onBuyCredits() }
                    .font(.caption.weight(.medium))
                Button("Go Unlimited") { onUpgrade() }
                    .font(.caption.weight(.medium))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.diamond.fill")
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Dismiss") {
                onDismiss()
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.blue)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Subscription Sheet

struct SubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Astronova Pro")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Unlock unlimited cosmic wisdom")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "Unlimited Messages", description: "Ask unlimited questions without daily limits")
                    
                    FeatureRow(icon: "heart.fill", title: "Detailed Love Forecasts", description: "Deep romantic insights and compatibility")
                    
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Birth Chart Readings", description: "Complete natal chart analysis")
                    
                    FeatureRow(icon: "briefcase.fill", title: "Career Forecasts", description: "Professional guidance and timing")
                    
                    FeatureRow(icon: "calendar", title: "Year Ahead Reports", description: "12-month cosmic roadmap")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                Spacer()
                
                // Pricing
                VStack(spacing: 16) {
                    Button {
                        Task {
                            let success = await BasicStoreManager.shared.purchaseProduct(productId: "astronova_pro_monthly")
                            if success {
                                await MainActor.run { dismiss() }
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text("Start Your Cosmic Journey")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text("$9.99/month")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .cornerRadius(12)
                    }
                    
                    Text("Cancel anytime in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
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
        case .welcome: return "circle.fill"
        case .question: return "questionmark.circle"
        case .insight: return "circle.fill"
        case .guidance: return "lightbulb.fill"
        case .prediction: return "circle.fill"
        }
    }
    
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
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

// Removed duplicate `displayName` computed property for `CosmicMessageType`.

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
                    .symbolEffect(.variableColor, options: .repeating)
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
    @State private var showingVoiceMode = false
    @State private var isDeepDiveEnabled = false
    
    private let allQuickQuestions = [
        "Should I change careers?",
        "What's my life purpose?",
        "How do I find balance?",
        "Will I find love soon?",
        "Is my relationship healthy?",
        "Should I sell out?",
        "Should I start a substack?",
        "Should I move cities?",
        "How to make better friends?",
        "What are my hidden strengths?",
        "Should I commit more?",
        "How to improve communication?",
        "Should I start my own business?",
        "Will I ever have my dream job?"
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Horizontal scrollable quick questions
            if !isInputFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allQuickQuestions.shuffled().prefix(6), id: \.self) { question in
                            Button {
                                onQuickQuestion(question)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            } label: {
                                Text(question)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Color(.systemGray5),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Deep Dive toggle button positioned above input area
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDeepDiveEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isDeepDiveEnabled ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                            .font(.system(size: 16))
                        Text("Deep Dive")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(isDeepDiveEnabled ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isDeepDiveEnabled ? Color.blue : Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isDeepDiveEnabled ? Color.blue : Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.leading, 16)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Input area container
            VStack(spacing: 0) {
                // Text input field with integrated buttons
                HStack(spacing: 12) {
                    // Text field
                    TextField("Ask anything...", text: $messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(1...5)
                        .focused($textFieldFocused)
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .onSubmit {
                            if !messageText.isEmpty {
                                onSend()
                            }
                        }
                    
                    // Voice button
                    Button {
                        showingVoiceMode = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 4)
                    
                    // Send button
                    Button {
                        if !messageText.isEmpty {
                            onSend()
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(messageText.isEmpty ? .gray : .white)
                            .frame(width: 32, height: 32)
                            .background(messageText.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                    .padding(.trailing, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            
        }
        .onChange(of: textFieldFocused) { _, focused in
            withAnimation(.easeInOut(duration: 0.3)) {
                isInputFocused = focused
            }
        }
        .sheet(isPresented: $showingVoiceMode) {
            VoiceModeView()
        }
    }
    
    private func hideKeyboard() {
        textFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ProfileTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingSettings = false
    @State private var showingAPITests = false
    @State private var bookmarkedReadings: [BookmarkedReading] = []
    
    var body: some View {
        NavigationStack {
            ManageDashboardView(bookmarks: $bookmarkedReadings)
                .environmentObject(auth)
                .navigationTitle("Manage")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            
                            #if DEBUG
                            Button {
                                showingAPITests = true
                            } label: {
                                Label("API Tests", systemImage: "network")
                            }
                            #endif
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .sheet(isPresented: $showingSettings) {
            EnhancedSettingsView(auth: auth)
        }
        .sheet(isPresented: $showingAPITests) {
            VStack {
                Text("API Testing")
                    .font(.headline)
                Text("API testing interface will be implemented")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToProfileSection)) { _ in
            // Reserved for future deep-links to sections
        }
    }
}

// MARK: - Manage Dashboard

struct ManageDashboardView: View {
    @EnvironmentObject private var auth: AuthState
    @Binding var bookmarks: [BookmarkedReading]
    
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingQuickBirthEdit = false
    
    var body: some View {
        List {
            // Profile
            Section(header: Text("Profile")) {
                ProfileSettingsRow(auth: auth)
                Button {
                    showingQuickBirthEdit = true
                } label: {
                    HStack {
                        Label("Edit Birth Information", systemImage: "person.text.rectangle")
                        Spacer()
                        Text(summaryBirthInfo(profile: auth.profileManager.profile))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Membership
            Section(header: Text("Membership")) {
                HStack {
                    Label("Astronova Pro", systemImage: "crown.fill")
                    Spacer()
                    // Use StoreKitManager in Release, BasicStoreManager in Debug
                    let isPro: Bool = {
                        #if DEBUG
                        return BasicStoreManager.shared.hasProSubscription
                        #else
                        return StoreKitManager.shared.hasProSubscription
                        #endif
                    }()
                    Text(isPro ? "Active" : "Free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(isPro ? "Manage" : "Start Pro") {
                        showingPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Library
            Section(header: Text("Library")) {
                NavigationLink {
                    BookmarksListScreen(bookmarks: $bookmarks)
                } label: {
                    HStack {
                        Label("Saved Bookmarks", systemImage: "bookmark.fill")
                        Spacer()
                        if !bookmarks.isEmpty {
                            Text("\(bookmarks.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    InlineReportsStoreSheet()
                        .environmentObject(auth)
                } label: {
                    Label("Reports Shop", systemImage: "doc.text.magnifyingglass")
                }
            }
            
            // Settings & Support
            Section(header: Text("Settings & Support")) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                
                NavigationLink {
                    DataPrivacyView()
                } label: {
                    Label("Data & Privacy", systemImage: "lock.shield.fill")
                }
                
                NavigationLink {
                    ExportDataView(auth: auth)
                } label: {
                    Label("Export My Data", systemImage: "square.and.arrow.up.on.square.fill")
                }
                
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "star.circle.fill")
                }
                
                Link(destination: URL(string: "mailto:support@astronova.app")!) {
                    Label("Contact Support", systemImage: "message.badge.filled.fill")
                }
                
                Link(destination: URL(string: "https://astronova.app/help")!) {
                    Label("Help Center", systemImage: "questionmark.app.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingSettings) {
            EnhancedSettingsView(auth: auth)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingQuickBirthEdit) {
            QuickBirthEditView()
                .environmentObject(auth)
        }
    }

    private func summaryBirthInfo(profile: UserProfile) -> String {
        let dateStr = {
            let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: profile.birthDate)
        }()
        let timeStr = profile.birthTime.map { t -> String in
            let f = DateFormatter(); f.timeStyle = .short; return f.string(from: t)
        } ?? "–"
        let placeStr = profile.birthPlace ?? "–"
        return "\(dateStr) • \(timeStr) • \(placeStr)"
    }
}

struct BookmarksListScreen: View {
    @Binding var bookmarks: [BookmarkedReading]
    
    var body: some View {
        BookmarkedReadingsView(bookmarks: bookmarks) { bookmark in
            bookmarks.removeAll { $0.id == bookmark.id }
        }
        .navigationTitle("Bookmarks")
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
                        .sheet(isPresented: $showingEditSheet) {
                            ProfileEditView(profileManager: auth.profileManager)
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
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingEditSheet) {
            ProfileEditView(profileManager: auth.profileManager)
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
    @ObservedObject var profileManager: UserProfileManager
    @State private var isEditing = false
    @State private var editedProfile: UserProfile
    
    init(profileManager: UserProfileManager) {
        self.profileManager = profileManager
        _editedProfile = State(initialValue: profileManager.profile)
    }
    
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
                        
                        Text(profileManager.profile.fullName.prefix(2).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text(profileManager.profile.fullName.isEmpty ? "Your Name" : profileManager.profile.fullName)
                            .font(.title2.weight(.semibold))
                        
                        if let sunSign = profileManager.profile.sunSign {
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
                                profileManager.updateProfile(editedProfile)
                            } else {
                                editedProfile = profileManager.profile
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
                            
                            // Birth Place with MapKit Autocomplete
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Place")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                MapKitAutocompleteView(
                                    selectedLocation: .constant(nil),
                                    placeholder: editedProfile.birthPlace ?? "City, State/Country"
                                ) { location in
                                    // Update profile when location is selected
                                    editedProfile.birthPlace = location.fullName
                                    editedProfile.birthLatitude = location.coordinate.latitude
                                    editedProfile.birthLongitude = location.coordinate.longitude
                                    editedProfile.timezone = location.timezone
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        VStack(spacing: 12) {
                            ProfileInfoRow(
                                title: "Birth Date",
                                value: formatDate(profileManager.profile.birthDate)
                            )
                            
                            ProfileInfoRow(
                                title: "Birth Time",
                                value: profileManager.profile.birthTime.map(formatTime) ?? "Not set"
                            )
                            
                            ProfileInfoRow(
                                title: "Birth Place",
                                value: profileManager.profile.birthPlace ?? "Not set"
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
                            value: profileManager.profile.sunSign ?? "Calculate from birth info"
                        )
                        
                        ProfileInfoRow(
                            title: "Moon Sign",
                            value: profileManager.profile.moonSign ?? "Requires birth time & place"
                        )
                        
                        ProfileInfoRow(
                            title: "Rising Sign",
                            value: profileManager.profile.risingSign ?? "Requires birth time & place"
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

// MARK: - Quick Birth Edit Sheet (fast 2‑tap flow)

struct QuickBirthEditView: View {
    @EnvironmentObject private var auth: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var birthDate: Date = Date()
    @State private var birthTime: Date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var unknownTime: Bool = false
    @State private var birthPlaceText: String = ""
    @State private var pendingLocation: LocationResult?
    @State private var saving: Bool = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Birth Date")) {
                    DatePicker("Date", selection: $birthDate, displayedComponents: .date)
                }
                Section(header: Text("Birth Time")) {
                    Toggle("I don't know my birth time", isOn: $unknownTime)
                    if !unknownTime {
                        DatePicker("Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section(header: Text("Birth Place")) {
                    MapKitAutocompleteView(
                        selectedLocation: $pendingLocation,
                        placeholder: birthPlaceText.isEmpty ? "City, State/Country" : birthPlaceText
                    ) { loc in
                        pendingLocation = loc
                        birthPlaceText = loc.fullName
                    }
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Birth Information")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(saving)
                }
            }
            .onAppear { preloadFromProfile() }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        var profile = auth.profileManager.profile
        profile.birthDate = birthDate
        profile.birthTime = unknownTime ? nil : birthTime
        if let loc = pendingLocation {
            profile.birthPlace = loc.fullName
            profile.birthLatitude = loc.coordinate.latitude
            profile.birthLongitude = loc.coordinate.longitude
            profile.timezone = loc.timezone
        } else if !birthPlaceText.isEmpty {
            profile.birthPlace = birthPlaceText
        }
        auth.profileManager.updateProfile(profile)
        do {
            try auth.profileManager.saveProfile()
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { self.error = "Failed to save: \(error.localizedDescription)" }
        }
    }

    private func preloadFromProfile() {
        let p = auth.profileManager.profile
        birthDate = p.birthDate
        if let t = p.birthTime { birthTime = t; unknownTime = false } else { unknownTime = true }
        birthPlaceText = p.birthPlace ?? ""
    }
}

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
        NavigationStack {
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
                        Label("Notifications", systemImage: "bell.badge.fill")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    if notificationsEnabled {
                        HStack {
                            Label("Daily Horoscope", systemImage: "sun.and.horizon.fill")
                            Spacer()
                            Toggle("", isOn: $dailyReminder)
                        }
                        
                        HStack {
                            Label("Weekly Report", systemImage: "calendar")
                            Spacer()
                            Toggle("", isOn: $weeklyReport)
                        }
                    }
                    
                    HStack {
                        Label("Theme", systemImage: "paintpalette.fill")
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
                        Label("Data & Privacy", systemImage: "lock.shield.fill")
                    }
                    
                    NavigationLink {
                        ExportDataView(auth: auth)
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up.on.square.fill")
                    }
                } header: {
                    Text("Data & Privacy")
                }
                
                // Support
                Section {
                    Link(destination: URL(string: "mailto:support@astronova.app")!) {
                        Label("Contact Support", systemImage: "message.badge.filled.fill")
                    }
                    
                    Link(destination: URL(string: "https://astronova.app/help")!) {
                        Label("Help Center", systemImage: "questionmark.app.fill")
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "star.circle.fill")
                    }
                } header: {
                    Text("Support")
                }
                
                // Account Actions
                Section {
                    Button {
                        Task {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            auth.signOut()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Label("Sign Out", systemImage: "door.left.hand.open")
                            Spacer()
                        }
                        .foregroundStyle(.red)
                    }
                    
                    Button {
                        showingAccountDeletion = true
                    } label: {
                        HStack {
                            Label("Delete Account", systemImage: "xmark.shield.fill")
                            Spacer()
                        }
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
                Task {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    
                    do {
                        try await APIServices.shared.deleteAccount()
                        await MainActor.run {
                            auth.signOut()
                            dismiss()
                        }
                    } catch {
                        // If API call fails, still sign out locally
                        await MainActor.run {
                            auth.signOut()
                            dismiss()
                        }
                    }
                }
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
            ProfileEditView(profileManager: auth.profileManager)
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
    
    @EnvironmentObject private var auth: AuthState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Horizontal Date Selector
                HorizontalDateSelector(selectedDate: $selectedDate)
                
                // Daily Synopsis (Free)
                DailySynopsisCard(
                    date: selectedDate,
                    onBookmark: onBookmark,
                    onDiscoverMore: {
                        // Premium Insights have been moved to the Discover page
                    }
                )
                .environmentObject(auth)
                
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
    let onDiscoverMore: () -> Void
    
    @State private var reading: HoroscopeReading?
    @EnvironmentObject private var auth: AuthState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Synopsis")
                        .font(.headline)
                    Text("General cosmic overview • \(DateFormatter.fullDate.string(from: date))")
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
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text("Free daily insight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    // Discovery Call-to-Action
                    Button {
                        onDiscoverMore()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Want deeper insights?")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Get personalized reports starting from $4.99")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.forward.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
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
        do {
            let sign = auth.profileManager.profile.sunSign?.lowercased() ?? "aries"
            let horoscopeResponse = try await APIServices.shared.getHoroscope(sign: sign, period: "daily")
            
            reading = HoroscopeReading(
                id: UUID(),
                date: date,
                type: .daily,
                title: "Daily Synopsis",
                content: horoscopeResponse.horoscope
            )
        } catch {
            // Fallback content if API fails
            reading = HoroscopeReading(
                id: UUID(),
                date: date,
                type: .daily,
                title: "Daily Synopsis",
                content: "Unable to load today's cosmic insights. Please check your connection and try again."
            )
        }
    }
}


// MARK: - Premium Insights Section

struct PremiumInsightsSection: View {
    let hasSubscription: Bool
    let onInsightTap: (String) -> Void
    let onViewReports: () -> Void
    let savedReports: [DetailedReport]
    
    private let insights = [
        InsightType(id: "love_forecast", title: "Love Forecast", icon: "heart.fill", color: .pink, description: "Romantic timing & compatibility"),
        InsightType(id: "birth_chart", title: "Birth Chart Reading", icon: "star.circle.fill", color: .purple, description: "Complete personality analysis"),
        InsightType(id: "career_forecast", title: "Career Forecast", icon: "briefcase.fill", color: .blue, description: "Professional guidance & timing"),
        InsightType(id: "year_ahead", title: "Year Ahead", icon: "calendar", color: .orange, description: "12-month cosmic roadmap")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detailed Insights")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                if !savedReports.isEmpty {
                    Button("View All (\(savedReports.count))") {
                        onViewReports()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                }
            }
            
            // Bento Box Layout
            VStack(spacing: 12) {
                // Top row: Large tile on left, two small tiles stacked on right
                HStack(spacing: 12) {
                    // Large Love Forecast tile
                    BentoInsightCard(
                        insight: insights[0],
                        hasSubscription: hasSubscription,
                        isGenerated: savedReports.contains { $0.type == insights[0].id },
                        size: .large,
                        onTap: {
                            onInsightTap(insights[0].id)
                        }
                    )
                    
                    // Stack of two small tiles
                    VStack(spacing: 12) {
                        BentoInsightCard(
                            insight: insights[1],
                            hasSubscription: hasSubscription,
                            isGenerated: savedReports.contains { $0.type == insights[1].id },
                            size: .small,
                            onTap: {
                                onInsightTap(insights[1].id)
                            }
                        )
                        
                        BentoInsightCard(
                            insight: insights[2],
                            hasSubscription: hasSubscription,
                            isGenerated: savedReports.contains { $0.type == insights[2].id },
                            size: .small,
                            onTap: {
                                onInsightTap(insights[2].id)
                            }
                        )
                    }
                }
                
                // Bottom row: Wide tile
                BentoInsightCard(
                    insight: insights[3],
                    hasSubscription: hasSubscription,
                    isGenerated: savedReports.contains { $0.type == insights[3].id },
                    size: .wide,
                    onTap: {
                        onInsightTap(insights[3].id)
                    }
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct InsightType {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let description: String
}

enum BentoSize {
    case small
    case large
    case wide
}

struct BentoInsightCard: View {
    let insight: InsightType
    let hasSubscription: Bool
    let isGenerated: Bool
    let size: BentoSize
    let onTap: () -> Void
    
    private var cardHeight: CGFloat {
        switch size {
        case .small: return 120
        case .large: return 252 // Height of two small cards + spacing
        case .wide: return 140
        }
    }
    
    private var iconSize: Font {
        switch size {
        case .small: return .title3
        case .large: return .largeTitle
        case .wide: return .title
        }
    }
    
    private var showDescription: Bool {
        size != .small
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        insight.color.opacity(0.15),
                        insight.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: size == .small ? 8 : 16) {
                    HStack(alignment: .top) {
                        Image(systemName: insight.icon)
                            .font(iconSize)
                            .foregroundStyle(insight.color)
                        
                        Spacer()
                        
                        if isGenerated {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(size == .small ? .subheadline : .headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(size == .small ? 2 : nil)
                        
                        if showDescription {
                            Text(insight.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }
                    
                    if size == .large {
                        Spacer()
                        
                        HStack {
                            Text("Tap to time travel")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(size == .small ? 12 : 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(insight.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: insight.color.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Scale button style for better interaction feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Keep the original InsightCard for backwards compatibility
struct InsightCard: View {
    let insight: InsightType
    let hasSubscription: Bool
    let isGenerated: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: insight.icon)
                        .font(.title2)
                        .foregroundStyle(insight.color)
                    
                    Spacer()
                    
                    if isGenerated {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(insight.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Report Generation Sheet

struct ReportGenerationSheet: View {
    let reportType: String
    let onGenerate: (String) -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject private var auth: AuthState
    @State private var isGenerating = false
    @State private var hasSubscription = false
    @State private var showingSubscription = false
    @State private var showPurchaseError = false
    @State private var showPaymentOptions = false
    @Environment(\.dismiss) private var dismiss
    
    private var reportInfo: InsightType {
        switch reportType {
        case "love_forecast":
            return InsightType(id: "love_forecast", title: "Love Forecast", icon: "heart.fill", color: .pink, description: "Comprehensive romantic analysis with timing and compatibility insights")
        case "birth_chart":
            return InsightType(id: "birth_chart", title: "Birth Chart Reading", icon: "star.circle.fill", color: .purple, description: "Complete astrological blueprint revealing personality and life purpose")
        case "career_forecast":
            return InsightType(id: "career_forecast", title: "Career Forecast", icon: "briefcase.fill", color: .blue, description: "Professional guidance with timing for career moves and opportunities")
        case "year_ahead":
            return InsightType(id: "year_ahead", title: "Year Ahead", icon: "calendar", color: .orange, description: "Month-by-month cosmic roadmap for the next 12 months")
        default:
            return InsightType(id: "unknown", title: "Report", icon: "doc.fill", color: .gray, description: "Detailed astrological analysis")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: reportInfo.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(reportInfo.color)
                        
                        Text("Sample \(reportInfo.title)")
                            .font(.title2.weight(.bold))
                        
                        Text("See what your personalised report will contain")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Sample Report Preview
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Overview (Unlocked)
                        ReportSectionPreview(
                            title: "Overview",
                            isLocked: false,
                            content: getSampleOverview(),
                            onLockedTap: nil
                        )
                        
                        // Section 2: Detailed Analysis (Locked)
                        ReportSectionPreview(
                            title: "Detailed Analysis",
                            isLocked: true,
                            content: "Your complete astrological blueprint including planetary positions, house placements, and aspect patterns...",
                            onLockedTap: {
                                showPaymentOptions = true
                            }
                        )
                        
                        // Section 3: Key Insights (Locked)
                        ReportSectionPreview(
                            title: "Key Life Insights",
                            isLocked: true,
                            content: "Discover your life purpose, karmic lessons, and soul's journey based on your unique cosmic signature...",
                            onLockedTap: {
                                showPaymentOptions = true
                            }
                        )
                        
                        // Section 4: Timing & Predictions (Locked)
                        ReportSectionPreview(
                            title: "Timing & Future Trends",
                            isLocked: true,
                            content: "Optimal timing for major life decisions, upcoming opportunities, and cosmic cycles affecting you...",
                            onLockedTap: {
                                showPaymentOptions = true
                            }
                        )
                        
                        // Section 5: Recommendations (Locked)
                        ReportSectionPreview(
                            title: "Personalised Recommendations",
                            isLocked: true,
                            content: "Specific actions, crystals, colors, and practices aligned with your astrological profile...",
                            onLockedTap: {
                                showPaymentOptions = true
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Action Buttons
                VStack(spacing: 16) {
                    if hasSubscription {
                        Button {
                            generateReport()
                        } label: {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                
                                Text(isGenerating ? "Generating..." : "Dive Deeper")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(reportInfo.color)
                            .cornerRadius(12)
                        }
                        .disabled(isGenerating)
                    } else {
                        // Purchase Options - Astronova Pro as primary decoy
                        VStack(spacing: 12) {
                            // Astronova Pro - Primary Option (Decoy)
                            Button {
                                showingSubscription = true
                            } label: {
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("BEST VALUE")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.green)
                                                .cornerRadius(4)
                                            
                                            Text("Astronova Pro")
                                                .font(.title2.weight(.bold))
                                            
                                            Text("$9.99/month")
                                                .font(.title3.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "crown.fill")
                                            .font(.largeTitle)
                                            .foregroundStyle(.yellow)
                                    }
                                    
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("All 4 detailed reports included")
                                                .font(.subheadline)
                                        }
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Unlimited AI chat conversations")
                                                .font(.subheadline)
                                        }
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Priority support & new features")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [reportInfo.color.opacity(0.8), reportInfo.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.3), lineWidth: 2)
                                )
                            }
                            
                            // Individual Report - Secondary Option
                            if ReportPricing.pricing(for: reportType) != nil {
                                Button {
                                    purchaseIndividualReport()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Single Report Only")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("Purchase \(reportInfo.title)")
                                                .font(.subheadline.weight(.medium))
                                            Text("from $12.99")
                                                .font(.headline.weight(.bold))
                                        }
                                        Spacer()
                                        Image(systemName: "apple.logo")
                                            .font(.title3)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundStyle(.primary)
                                    .background(.quaternary)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    Text("All reports are saved to your profile for future reference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("Premium Insight")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionSheet()
        }
        .sheet(isPresented: $showPaymentOptions) {
            PaymentOptionsSheet(
                reportType: reportType,
                reportInfo: reportInfo,
                onPurchaseIndividual: {
                    showPaymentOptions = false
                    purchaseIndividualReport()
                },
                onSubscribe: {
                    showPaymentOptions = false
                    showingSubscription = true
                }
            )
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to complete purchase. Please try again.")
        }
    }
    
    private func generateReport() {
        isGenerating = true
        onGenerate(reportType)
    }
    
    private func purchaseIndividualReport() {
        isGenerating = true
        Task {
            let success = await BasicStoreManager.shared.purchaseProduct(productId: reportType)
            await MainActor.run {
                if success {
                    onGenerate(reportType)
                } else {
                    isGenerating = false
                    showPurchaseError = true
                }
            }
        }
    }
    
    private func getSampleOverview() -> String {
        switch reportType {
        case "love_forecast":
            return "Based on your astrological profile, you are entering a powerful period for romantic connections. Venus in your 5th house suggests heightened charm and magnetism. The upcoming months show strong potential for meaningful encounters, especially during the full moon phases..."
        case "birth_chart":
            return "You are a unique blend of fire and water elements, creating a dynamic personality that balances passion with emotional depth. Your Sun sign reveals your core identity, while your Moon sign shows your emotional nature. With Mercury in an air sign, you possess quick wit and excellent communication skills..."
        case "career_forecast":
            return "Your professional life is entering an expansive phase. Jupiter's transit through your 10th house of career indicates opportunities for growth and recognition. Your natural leadership abilities combined with your strategic thinking make you well-suited for positions of authority..."
        case "year_ahead":
            return "The year ahead promises transformation and growth across multiple life areas. The first quarter focuses on personal development and self-discovery. Spring brings opportunities in relationships and partnerships. Summer emphasizes career advancement, while autumn encourages spiritual growth..."
        default:
            return "This comprehensive analysis reveals key patterns in your astrological chart that influence your life path. Understanding these cosmic energies helps you make informed decisions and align with your highest potential..."
        }
    }
}

struct ReportSectionPreview: View {
    let title: String
    let isLocked: Bool
    let content: String
    let onLockedTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("LOCKED")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                }
            }
            
            if isLocked {
                // Locked content - blurred preview
                Button(action: {
                    onLockedTap?()
                }) {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .blur(radius: 6)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.orange)
                                Text("Tap to Unlock")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial)
                        )
                        .frame(minHeight: 80)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            } else {
                // Unlocked content
                Text(content)
                    .font(.body)
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
    }
}

struct PaymentOptionsSheet: View {
    let reportType: String
    let reportInfo: InsightType
    let onPurchaseIndividual: () -> Void
    let onSubscribe: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(reportInfo.color)
                    
                    Text("Unlock Full Report")
                        .font(.title2.weight(.bold))
                    
                    Text("Choose how you'd like to access your \(reportInfo.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Options
                VStack(spacing: 16) {
                    // Astronova Pro Option
                    Button {
                        onSubscribe()
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("RECOMMENDED")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.green)
                                        .cornerRadius(4)
                                    
                                    Text("Astronova Pro")
                                        .font(.title3.weight(.bold))
                                    
                                    Text("$9.99/month")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundStyle(.yellow)
                            }
                            
                            Text("Unlock all reports + unlimited features")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [reportInfo.color.opacity(0.8), reportInfo.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                    }
                    
                    // Individual Report Option
                    if ReportPricing.pricing(for: reportType) != nil {
                        Button {
                            onPurchaseIndividual()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Single Report")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(reportInfo.title)
                                        .font(.headline)
                                    Text("from $12.99")
                                        .font(.title3.weight(.bold))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "doc.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(reportInfo.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.quaternary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Choose Your Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Inline minimal Reports Store to avoid cross-target visibility issues
struct InlineReportsStoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var isPurchasing: String? = nil
    
    private let offers: [ShopCatalog.Report] = ShopCatalog.reports
    
    var body: some View {
        NavigationStack {
            List {
                Section("Detailed Reports") {
                    ForEach(offers) { offer in
                        HStack(spacing: 12) {
                            Circle().fill(offer.color.opacity(0.15)).frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(offer.title).font(.headline)
                                Text(offer.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task { await buy(offer) }
                            } label: {
                                HStack(spacing: 6) {
                                    if isPurchasing == offer.productId { ProgressView().tint(.white) }
                                    Text(isPurchasing == offer.productId ? "Processing…" : ShopCatalog.price(for: offer.productId))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isPurchasing != nil)
                        }
                    }
                }
            }
            .navigationTitle("Reports Shop")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    
    private func buy(_ offer: ShopCatalog.Report) async {
        guard isPurchasing == nil else { return }
        isPurchasing = offer.productId
        defer { isPurchasing = nil }
        _ = await BasicStoreManager.shared.purchaseProduct(productId: offer.productId)
        // Optionally kick off async generation using APIServices as in full view
    }
}

// Inline minimal Chat Packages sheet
struct InlineChatPackagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @State private var isPurchasing: String? = nil
    
    private let packs: [ShopCatalog.ChatPack] = ShopCatalog.chatPacks
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Available credits: \(chatCredits)")) {
                    ForEach(packs) { p in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.title).font(.headline)
                                Text(p.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task { await buy(p) }
                            } label: {
                                HStack(spacing: 6) {
                                    if isPurchasing == p.productId { ProgressView().tint(.white) }
                                    Text(isPurchasing == p.productId ? "Processing…" : ShopCatalog.price(for: p.productId))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isPurchasing != nil)
                        }
                    }
                }
            }
            .navigationTitle("Chat Packages")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    
    private func buy(_ p: ShopCatalog.ChatPack) async {
        guard isPurchasing == nil else { return }
        isPurchasing = p.productId
        defer { isPurchasing = nil }
        _ = await BasicStoreManager.shared.purchaseProduct(productId: p.productId)
    }
}

struct SimpleFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Reports Library View

struct ReportsLibraryView: View {
    let reports: [DetailedReport]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReport: DetailedReport?
    @State private var showingReportDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if reports.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No Reports Yet")
                                .font(.title2.weight(.semibold))
                            
                            Text("Generate your first detailed insight to see it here")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(reports, id: \.reportId) { report in
                            ReportLibraryCard(
                                report: report,
                                onTap: {
                                    selectedReport = report
                                    showingReportDetail = true
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingReportDetail) {
            if let report = selectedReport {
                ReportDetailView(report: report)
            }
        }
    }
}

struct ReportLibraryCard: View {
    let report: DetailedReport
    let onTap: () -> Void
    
    private var reportInfo: InsightType {
        switch report.type {
        case "love_forecast":
            return InsightType(id: "love_forecast", title: "Love Forecast", icon: "heart.fill", color: .pink, description: "Romantic analysis")
        case "birth_chart":
            return InsightType(id: "birth_chart", title: "Birth Chart Reading", icon: "star.circle.fill", color: .purple, description: "Personality blueprint")
        case "career_forecast":
            return InsightType(id: "career_forecast", title: "Career Forecast", icon: "briefcase.fill", color: .blue, description: "Professional guidance")
        case "year_ahead":
            return InsightType(id: "year_ahead", title: "Year Ahead", icon: "calendar", color: .orange, description: "Cosmic roadmap")
        default:
            return InsightType(id: "unknown", title: "Report", icon: "doc.fill", color: .gray, description: "Analysis")
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        if let date = ISO8601DateFormatter().date(from: report.generatedAt) {
            return formatter.string(from: date)
        }
        return report.generatedAt
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: reportInfo.icon)
                        .font(.title2)
                        .foregroundStyle(reportInfo.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("Generated \(formattedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Key insights preview
                if !report.keyInsights.isEmpty {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Text("\(report.keyInsights.count) key insights")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.orange)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(reportInfo.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Report Detail View

struct ReportDetailView: View {
    let report: DetailedReport
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var showingShareSheet = false
    @State private var showingPlanetaryTutorial = false
    
    private let apiServices = APIServices.shared
    
    private var reportInfo: InsightType {
        switch report.type {
        case "love_forecast":
            return InsightType(id: "love_forecast", title: "Love Forecast", icon: "heart.fill", color: .pink, description: "Romantic analysis")
        case "birth_chart":
            return InsightType(id: "birth_chart", title: "Birth Chart Reading", icon: "star.circle.fill", color: .purple, description: "Personality blueprint")
        case "career_forecast":
            return InsightType(id: "career_forecast", title: "Career Forecast", icon: "briefcase.fill", color: .blue, description: "Professional guidance")
        case "year_ahead":
            return InsightType(id: "year_ahead", title: "Year Ahead", icon: "calendar", color: .orange, description: "Cosmic roadmap")
        default:
            return InsightType(id: "unknown", title: "Report", icon: "doc.fill", color: .gray, description: "Analysis")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: reportInfo.icon)
                                .font(.title)
                                .foregroundStyle(reportInfo.color)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(report.title)
                                    .font(.title2.weight(.bold))
                                
                                Text("Generated \(formatDate(report.generatedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(report.summary)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Key Insights
                    if !report.keyInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights")
                                .font(.title3.weight(.bold))
                            
                            ForEach(report.keyInsights.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.body)
                                        .foregroundStyle(.orange)
                                    
                                    Text(report.keyInsights[index])
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                    
                    // Full Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detailed Analysis")
                            .font(.title3.weight(.bold))
                        
                        Text(report.content)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Tutorial Entry Point (only for birth chart reports)
                    if report.type == "birth_chart" {
                        tutorialEntryPoint
                    }
                }
                .padding()
            }
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            downloadPDF()
                        } label: {
                            Label("Download PDF", systemImage: "arrow.down.doc.fill")
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "shareplay")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func downloadPDF() {
        // PDF download implementation
        Task {
            do {
                // Generate and download PDF via API
                let pdfData = try await APIServices.shared.generateReportPDF(reportId: report.reportId)
                // Save PDF to user's files or share
                await savePDFToFiles(data: pdfData, filename: "\(report.title).pdf")
            } catch {
                print("Failed to download PDF: \(error)")
            }
        }
    }
    
    @MainActor
    private func savePDFToFiles(data: Data, filename: String) async {
        // Save PDF to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: pdfURL)
            print("PDF saved to: \(pdfURL)")
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
    
    // MARK: - Tutorial Entry Point
    
    private var tutorialEntryPoint: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                        
                        Text("Learn How This Was Calculated")
                            .font(.headline.weight(.semibold))
                    }
                    
                    Text("Discover the ancient art of birth chart calculations with our interactive tutorial")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.purple)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                showingPlanetaryTutorial = true
            }
        }
        .sheet(isPresented: $showingPlanetaryTutorial) {
            NavigationStack {
                VStack {
                    Text("Planetary Calculations Tutorial")
                        .font(.title)
                        .padding()
                    
                    Text("Tutorial content will be available soon.")
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Tutorial")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingPlanetaryTutorial = false
                        }
                    }
                }
            }
        }
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
        NavigationStack {
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
        NavigationStack {
            Form {
                Section("Account") {
                    Button("Sign Out", role: .destructive) {
                        auth.signOut()
                    }
                }
                
                Section("Notifications") {
                    Toggle("Daily Horoscope", isOn: .constant(true))
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
    @State private var contacts: [CNContact] = []
    @State private var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            VStack {
                if hasContactsAccess {
                    // Contacts list
                    List(filteredContacts, id: \.identifier) { contact in
                        Button {
                            let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown"
                            selectedName = fullName
                            dismiss()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(getInitials(from: contact))
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown")
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .searchable(text: $searchText, prompt: "Search contacts")
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
                checkContactsAuthorization()
            }
        }
    }
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { 
                let fullName = CNContactFormatter.string(from: $0, style: .fullName) ?? ""
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.hasContactsAccess = true
                    self.loadContacts()
                } else {
                    print("Contact access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkContactsAuthorization() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authorizationStatus {
        case .authorized:
            hasContactsAccess = true
            loadContacts()
        case .denied, .restricted:
            hasContactsAccess = false
        case .notDetermined:
            hasContactsAccess = false
        case .limited:
            hasContactsAccess = true
            loadContacts()
        @unknown default:
            hasContactsAccess = false
        }
    }
    
    private func loadContacts() {
        Task {
            do {
                let store = CNContactStore()
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                
                var fetchedContacts: [CNContact] = []
                try store.enumerateContacts(with: request) { contact, _ in
                    fetchedContacts.append(contact)
                }
                
                let sortedContacts = fetchedContacts.sorted {
                    let name1 = CNContactFormatter.string(from: $0, style: .fullName) ?? ""
                    let name2 = CNContactFormatter.string(from: $1, style: .fullName) ?? ""
                    return name1 < name2
                }
                
                await MainActor.run {
                    self.contacts = sortedContacts
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }
    
    private func getInitials(from contact: CNContact) -> String {
        let firstName = contact.givenName.prefix(1)
        let lastName = contact.familyName.prefix(1)
        return "\(firstName)\(lastName)".uppercased()
    }
}

// MARK: - Tab Guide Overlay

struct TabGuideOverlay: View {
    let step: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var animateContent = false
    
    private var safeStep: Int {
        min(max(0, step), 3)
    }
    
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
            description: "Ask questions for insights about love, career, and life decisions in a minimal interface.",
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
            Rectangle()
                .fill(.black.opacity(0.4))
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: guides[safeStep].icon)
                            .font(.system(size: 50))
                            .foregroundStyle(guides[safeStep].color)
                            .scaleEffect(animateContent ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateContent)
                        
                        VStack(spacing: 8) {
                            Text(guides[safeStep].title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text(guides[safeStep].description)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index <= safeStep ? guides[safeStep].color : .gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == safeStep ? 1.3 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: safeStep)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: onNext) {
                            HStack {
                                if safeStep == 3 {
                                    Text("Start Your Journey")
                                        .font(.headline.weight(.semibold))
                                    Image(systemName: "arrow.forward.circle.fill")
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
                            .background(guides[safeStep].color, in: RoundedRectangle(cornerRadius: 25))
                            .shadow(color: guides[safeStep].color.opacity(0.3), radius: 8, y: 4)
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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


// MARK: - Compelling Landing View

struct CompellingLandingView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var inProgress = false
    @State private var currentPhase = 0
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var showCelestialData = false
    @State private var currentTime = Date()
    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var showCosmicInsight = false
    @State private var personalizedInsight = ""
    @State private var currentMoonPhase = "🌙"
    @State private var currentEnergy = "Transformative"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Dynamic Cosmic Background
            cosmicBackground
            
            VStack(spacing: 0) {
                switch currentPhase {
                case 0:
                    cosmicHookPhase
                default:
                    signInPhase
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateCosmicData()
        }
        .onAppear {
            startCosmicJourney()
            generatePersonalizedInsight()
        }
    }
    
    // MARK: - Cosmic Background
    
    private var cosmicBackground: some View {
        ZStack {
            // Deep space gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.25),
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.2, green: 0.15, blue: 0.4)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
            
            // Animated constellation
            ForEach(0..<50, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(animateStars ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateStars
                    )
            }
            
            // Flowing cosmic particles
            ForEach(0..<15, id: \.self) { i in
                cosmicParticle(index: i)
            }
        }
    }
    
    private func cosmicParticle(index: Int) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.purple.opacity(0.6), .blue.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: CGFloat.random(in: 20...40))
            .blur(radius: 3)
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )
            .animation(
                .easeInOut(duration: Double.random(in: 6...12))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...3)),
                value: animateStars
            )
            .offset(
                x: animateStars ? CGFloat.random(in: -50...50) : 0,
                y: animateStars ? CGFloat.random(in: -30...30) : 0
            )
    }
    
    // MARK: - Instant Cosmic Experience
    
    private var cosmicHookPhase: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    // Cosmic symbol
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.purple.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateStars ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateStars)
                        
                        Text("🌟")
                            .font(.system(size: 32))
                            .rotationEffect(.degrees(animateStars ? 360 : 0))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateStars)
                    }
                    
                    // Main headline
                    VStack(spacing: 12) {
                        Text("Your Cosmic Journey Starts Here")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Discover your astrological blueprint and unlock the wisdom of the stars")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    // Quick cosmic data preview
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(currentMoonPhase)
                                .font(.title2)
                            Text("Moon")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 4) {
                            Text("⚡")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            Text("Energy")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 4) {
                            Text("🌟")
                                .font(.title2)
                            Text("Insight")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Call to action
                    Text("Begin Your Cosmic Profile")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    // Sign in buttons
                    signInButtons
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(height: geometry.size.height)
        }
    }
    
    
    private var cosmicDataDisplay: some View {
        VStack(spacing: 24) {
            // Current celestial configuration
            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text(currentMoonPhase)
                        .font(.system(size: 40))
                    Text("Moon Phase")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    Text("⚡")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow)
                    Text("Energy: \(currentEnergy)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    Text("🌟")
                        .font(.system(size: 40))
                    Text("Manifestation")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Location coordinates
            if let location = userLocation {
                VStack(spacing: 8) {
                    Text("Your Celestial Coordinates")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white)
                    
                    Text("\(location.coordinate.latitude, specifier: "%.2f")°N, \(location.coordinate.longitude, specifier: "%.2f")°W")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.cyan)
                    
                    Text("Planetary alignment detected")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                )
            }
        }
        .opacity(showCelestialData ? 1 : 0)
        .animation(.easeInOut(duration: 1).delay(0.5), value: showCelestialData)
        .onAppear {
            showCelestialData = true
        }
    }
    
    
    // MARK: - Sign In Phase
    
    private var signInPhase: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("🌌")
                    .font(.system(size: 60))
                
                Text("Complete Your Profile")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Get personalized insights and your complete birth chart")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            signInButtons
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Sign In Buttons
    
    private var signInButtons: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = UUID().uuidString
                },
                onCompletion: { result in
                    Task {
                        await handleSignInResult(result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .disabled(inProgress)
            .overlay(
                Group {
                    if inProgress {
                        ProgressView()
                            .foregroundStyle(Color.black)
                    }
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            
            Button("Continue without signing in") {
                Task {
                    await handleSkipSignIn()
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.8))
            .disabled(inProgress)
        }
    }
    
    // MARK: - Helper Functions
    
    private func startCosmicJourney() {
        withAnimation(.easeInOut(duration: 1)) {
            animateStars = true
            animateGradient = true
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private func updateCosmicData() {
        // Update moon phase and energy based on current time
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        switch hour {
        case 0...5:
            currentMoonPhase = "🌑"
            currentEnergy = "Mysterious"
        case 6...11:
            currentMoonPhase = "🌒"
            currentEnergy = "Awakening"
        case 12...17:
            currentMoonPhase = "🌓"
            currentEnergy = "Radiant"
        case 18...23:
            currentMoonPhase = "🌔"
            currentEnergy = "Transformative"
        default:
            currentMoonPhase = "🌙"
            currentEnergy = "Mystical"
        }
    }
    
    private func generatePersonalizedInsight() {
        Task {
            // Use static insights for now
            let staticInsights = [
                "The celestial alignment at this moment reveals a powerful portal of transformation opening in your life. Your soul is ready to embrace its next evolutionary leap.",
                "The cosmic winds carry whispers of destiny toward you. This is a time of manifestation - your deepest intentions are rippling through the universe.",
                "Your energy signature resonates with ancient wisdom tonight. The stars have aligned to unlock hidden potentials within your cosmic blueprint.",
                "The universe recognizes your unique frequency. You are being called to step into your power and embrace the magic that flows through you.",
                "Cosmic currents are shifting in your favor. This moment marks a significant turning point in your spiritual journey - trust the process."
            ]
            
            await MainActor.run {
                personalizedInsight = staticInsights.randomElement() ?? staticInsights[0]
            }
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        if let location = locationManager.location {
            userLocation = location
        }
    }
    
    // MARK: - Sign In Handlers
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        inProgress = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                    let displayName = "\(givenName) \(familyName)"
                    UserDefaults.standard.set(displayName, forKey: "user_full_name")
                    
                    await MainActor.run {
                        auth.profileManager.profile.fullName = displayName
                    }
                }
                
                if let email = email {
                    UserDefaults.standard.set(email, forKey: "user_email")
                }
                
                UserDefaults.standard.set(userID, forKey: "apple_user_id")
                await auth.requestSignIn()
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error)")
        }
        
        inProgress = false
    }
    
    private func handleSkipSignIn() async {
        inProgress = true
        UserDefaults.standard.set(true, forKey: "is_anonymous_user")
        await auth.requestSignIn()
        inProgress = false
    }
}


// MARK: - Voice Mode View

struct VoiceModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var transcript = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.indigo.opacity(0.2),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Tap to speak")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Recording button
                    Button {
                        isRecording.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)
                    
                    if !transcript.isEmpty {
                        Text(transcript)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Voice Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Keyboard Dismiss Extension

extension View {
    func keyboardDismissButton() -> some View {
        self
    }
}

// MARK: - Duplicate Notification Extension Removed

// (Original definitions for `switchToTab` and `switchToProfileSection` exist at
// the top of this file.)
