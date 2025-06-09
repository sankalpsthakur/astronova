import SwiftUI
import Contacts
import ContactsUI
import Combine
import StoreKit
import AuthenticationServices
import CoreLocation

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

// MARK: - Store Manager (Placeholder for future StoreKit integration)

class StoreManager: ObservableObject, StoreManagerProtocol {
    static let shared = StoreManager()
    
    @Published var hasProSubscription = false
    @Published var products: [String: String] = [:]  // Product ID to localized price
    
    init() {
        // Load subscription status from UserDefaults for now
        hasProSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }
    
    func loadProducts() {
        // TODO: Implement StoreKit product loading
        // This would load actual App Store product information including localized prices
        products = [
            "love_forecast": "$4.99",
            "birth_chart": "$7.99", 
            "career_forecast": "$5.99",
            "year_ahead": "$9.99",
            "astronova_pro_monthly": "$9.99"
        ]
    }
    
    func purchaseProduct(productId: String) async -> Bool {
        // TODO: Implement StoreKit purchase flow
        // For now, simulate successful purchase for individual reports
        if productId == "astronova_pro_monthly" {
            hasProSubscription = true
            UserDefaults.standard.set(true, forKey: "hasAstronovaPro")
        }
        return true
    }
}

// MARK: - Notification.Name Helpers

extension Notification.Name {
    static let switchToTab            = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
}

// Duplicate Notification.Name extension removed. The definitions for
// `switchToTab` and `switchToProfileSection` already exist at the top of this
// file.

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
        case 1: return isValidName(fullName)
        case 2: return isValidBirthDate(birthDate)
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
            
            Born on \(formatDate(birthDate)) at \(formatTime(birthTime))\(locationText), the stars reveal fascinating insights about your celestial blueprint.
            
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
            "Your birth on \(formatDate(birthDate)) at \(formatTime(birthTime))\(locationText) reveals a powerful cosmic alignment. The stars suggest you have natural leadership qualities and a deep connection to creative energies.",
            "Born under the influence of \(formatDate(birthDate))\(locationText), you carry the gift of intuition and emotional wisdom. The universe has blessed you with the ability to inspire others.",
            "The celestial patterns on \(formatDate(birthDate)) at \(formatTime(birthTime)) indicate a soul destined for transformation and growth. Your journey is one of continuous evolution and self-discovery."
        ]
        
        await MainActor.run {
            personalizedInsight = fallbackInsights.randomElement() ?? fallbackInsights[0]
            showPersonalizedInsight()
        }
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
                        .symbolEffect(.variableColor, options: .repeating)
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
    @State private var validationError: String?
    
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
                        // `.bounce` is iOS 18+. Use `.pulse` which is available earlier.
                        .symbolEffect(.pulse, options: .repeating)
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
                            Image(systemName: "exclamationmark.triangle.fill")
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
        .onAppear {
            animateIcon = true
            // Auto-focus text field for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
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
                            Image(systemName: "exclamationmark.triangle.fill")
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
            }
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
            validateBirthDate(birthDate)
        }
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
    @State private var searchResults: [LocationResult] = []
    @State private var isSearching = false
    @State private var showDropdown = false
    @State private var searchTask: Task<Void, Never>?
    @EnvironmentObject private var auth: AuthState
    
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
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
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
                                        Image(systemName: "location.fill")
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
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Perfect! Location validated with coordinates.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Select a location from the dropdown for best results, or skip to add later.")
                                    .font(.caption)
                                    .foregroundStyle(.orange.opacity(0.9))
                            }
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: birthPlace.isEmpty)
                    }
                    
                    // Optional skip hint
                    if birthPlace.isEmpty && !showDropdown {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Birth location is optional - you can always add it later in your profile.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
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
                // Try Google Places API first, fallback to existing API
                let results: [LocationResult]
                // TODO: Re-enable GooglePlacesService when compilation issues are resolved
                /*
                do {
                    results = try await GooglePlacesService.shared.searchPlaces(query: query)
                } catch {
                    print("Google Places search failed, using fallback: \(error)")
                    results = await auth.profileManager.searchLocations(query: query)
                }
                */
                results = await auth.profileManager.searchLocations(query: query)
                
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
        .keyboardDismissButton()
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
                        // Icon with background
                        ZStack {
                            if selectedTab == index {
                                Circle()
                                    .fill(.blue.gradient)
                                    .frame(width: 28, height: 28)
                                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
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
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                } else {
                                    Image(systemName: tabs[index].icon)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .frame(width: 28, height: 28)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].title)
                .accessibilityHint("Tab \(index + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            .regularMaterial,
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

// MARK: - Simple Tab Views

struct TodayTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingWelcome = false
    @State private var animateWelcome = false
    @State private var planetaryPositions: [PlanetaryPosition] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeSection
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
                    
                    todaysHoroscopeSection
                    
                    planetaryPositionsSection
                    
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
                let springAnimation = Animation.spring(response: 0.8, dampingFraction: 0.6)
                let delayedAnimation = springAnimation.delay(0.5)
                withAnimation(delayedAnimation) {
                    animateWelcome = true
                }
            }
            // TODO: Re-enable when PlanetaryDataService is properly integrated
            /*
            Task {
                do {
                    planetaryPositions = try await PlanetaryDataService.shared.getCurrentPlanetaryPositions()
                } catch {
                    print("Failed to load planetary positions: \(error)")
                }
            }
            */
            planetaryPositions = [] // Temporary fallback
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
            
            keyThemesSection
            
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
    
    @ViewBuilder
    private var planetaryPositionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Planetary Energies")
                .font(.headline)
            
            Text("Planetary data will be displayed here when available.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var shouldShowWelcome: Bool {
        // Show welcome for first few app opens
        UserDefaults.standard.integer(forKey: "app_launch_count") < 3
    }
    
    @ViewBuilder
    private var welcomeSection: some View {
        if shouldShowWelcome {
            WelcomeToTodayCard(onDismiss: {
                showingWelcome = false
            })
            .transition(AnyTransition.scale.combined(with: .opacity))
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
        (name: "Sarah", sun: "Leo", moon: "Pisces", rising: "Virgo"),
        (name: "Alex", sun: "Gemini", moon: "Scorpio", rising: "Libra"),
        (name: "Jordan", sun: "Aquarius", moon: "Taurus", rising: "Cancer")
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
        CosmicMessage(id: "welcome", text: "✨ Welcome to the Cosmic Nexus! I'm your AI astrologer, here to illuminate your path through the stars. What cosmic wisdom can I share with you today?", isUser: false, messageType: .welcome, timestamp: Date().addingTimeInterval(-3600))
    ]
    @State private var animateStars = false
    @State private var animateGradient = false
    @State private var showingTypingIndicator = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var dailyMessageCount = 0
    @State private var hasSubscription = false
    @State private var showingSubscriptionSheet = false
    
    @EnvironmentObject private var auth: AuthState
    private let apiServices = APIServices.shared
    private let freeMessageLimit = 5
    
    var body: some View {
        NavigationView {
            ZStack {
                // Cosmic animated background
                CosmicChatBackground(animateStars: $animateStars, animateGradient: $animateGradient)
                
                VStack(spacing: 0) {
                    // Message Limit Banner (for free users)
                    if !hasSubscription {
                        MessageLimitBanner(
                            used: dailyMessageCount,
                            limit: freeMessageLimit,
                            onUpgrade: {
                                showingSubscriptionSheet = true
                            }
                        )
                    }
                    
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
                            
                            // Error message
                            if let errorMessage = errorMessage {
                                ErrorMessageView(message: errorMessage) {
                                    self.errorMessage = nil
                                }
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
                    .disabled(isLoading || (!hasSubscription && dailyMessageCount >= freeMessageLimit))
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
            loadMessageCount()
            checkSubscriptionStatus()
            // TODO: Re-enable when ContentManagementService is properly integrated
            /*
            Task {
                do {
                    quickQuestions = try await ContentManagementService.shared.getQuickQuestions()
                } catch {
                    print("Failed to load quick questions: \(error)")
                }
            }
            */
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            SubscriptionSheet()
        }
    }
    
    // TODO: Re-enable when QuickQuestion is properly integrated
    // @State private var quickQuestions: [QuickQuestion] = []
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Check message limit for free users
        if !hasSubscription && dailyMessageCount >= freeMessageLimit {
            errorMessage = "✨ You've reached your daily message limit! Upgrade to Astronova Plus for unlimited cosmic conversations and unlock the full power of the stars."
            return
        }
        
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
        errorMessage = nil
        isLoading = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingTypingIndicator = true
        }
        
        Task {
            do {
                let context = ChatContext(
                    userChart: auth.profileManager.lastChart,
                    currentTransits: nil,
                    preferences: nil
                )
                
                let response = try await apiServices.sendChatMessage(currentMessage, context: context)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingTypingIndicator = false
                        isLoading = false
                    }
                    
                    let aiMessage = CosmicMessage(
                        id: UUID().uuidString,
                        text: response.reply,
                        isUser: false,
                        messageType: .insight,
                        timestamp: Date()
                    )
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(aiMessage)
                    }
                    
                    // Increment message count for free users
                    if !hasSubscription {
                        dailyMessageCount += 1
                        saveMessageCount()
                    }
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingTypingIndicator = false
                        isLoading = false
                    }
                    
                    // Show error message instead of fake responses
                    let errorMessage = CosmicMessage(
                        id: UUID().uuidString,
                        text: "🌙 I'm having trouble connecting to the cosmic network right now. Please check your internet connection and try again.",
                        isUser: false,
                        messageType: .guidance,
                        timestamp: Date()
                    )
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(errorMessage)
                    }
                    
                    print("Chat API error: \(error)")
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
    
    var body: some View {
        HStack {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(.orange)
            
            Text("\(used)/\(limit) free messages today")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if used >= limit {
                Button("Upgrade to Plus") {
                    onUpgrade()
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.blue)
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
            Image(systemName: "exclamationmark.triangle.fill")
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
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
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
                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "Unlimited Chat Messages", description: "Chat with AI astrologer without daily limits")
                    
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
                            let success = await StoreManager.shared.purchaseProduct(productId: "astronova_pro_monthly")
                            if success {
                                await MainActor.run {
                                    dismiss()
                                }
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
        case .welcome: return "sparkles"
        case .question: return "questionmark.circle"
        case .insight: return "star.fill"
        case .guidance: return "lightbulb.fill"
        case .prediction: return "crystal.ball"
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
                        .symbolEffect(.variableColor)
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
    
    // TODO: Re-enable when QuickQuestion is properly integrated
    // @State private var quickQuestions: [QuickQuestion] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Questions Scroll
            if !isInputFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // TODO: Re-enable when quickQuestions is properly integrated
                        /*
                        ForEach(quickQuestions, id: \.id) { question in
                            Button {
                                onQuickQuestion(question.text)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            } label: {
                                Text(question.text)
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
                        */
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
            .onAppear {
                // TODO: Re-enable when ContentManagementService is properly integrated
                /*
                Task {
                    do {
                        quickQuestions = try await ContentManagementService.shared.getQuickQuestions()
                    } catch {
                        print("Failed to load quick questions: \(error)")
                    }
                }
                */
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
                            action: { 
                                NotificationCenter.default.post(name: .switchToProfileSection, object: 1)
                            }
                        )
                        
                        NavigationRowView(
                            title: "Today's Horoscope",
                            subtitle: "See what the stars have in store",
                            icon: "calendar.circle.fill",
                            action: { 
                                NotificationCenter.default.post(name: .switchToTab, object: 0)
                            }
                        )
                        
                        NavigationRowView(
                            title: "Compatibility Check",
                            subtitle: "Compare with friends and partners",
                            icon: "heart.circle.fill",
                            action: { 
                                NotificationCenter.default.post(name: .switchToTab, object: 1)
                            }
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
                            
                            // Birth Place with Google Places Autocomplete
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Birth Place")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                // TODO: Re-enable GooglePlacesAutocompleteView when compilation issues are resolved
                                /*
                                GooglePlacesAutocompleteView(
                                    selectedLocation: Binding(
                                        get: { 
                                            // Convert current birth place to LocationResult if available
                                            if let birthPlace = editedProfile.birthPlace,
                                               let coordinates = editedProfile.birthCoordinates,
                                               let timezone = editedProfile.timezone {
                                                return LocationResult(
                                                    fullName: birthPlace,
                                                    coordinate: coordinates,
                                                    timezone: timezone
                                                )
                                            }
                                            return nil
                                        },
                                        set: { newLocation in
                                            if let location = newLocation {
                                                editedProfile.birthPlace = location.fullName
                                                editedProfile.birthCoordinates = location.coordinate
                                                editedProfile.timezone = location.timezone
                                            } else {
                                                editedProfile.birthPlace = nil
                                                editedProfile.birthCoordinates = nil
                                                editedProfile.timezone = nil
                                            }
                                        }
                                    ),
                                    placeholder: "City, State/Country"
                                ) { location in
                                    // Update profile when location is selected
                                    editedProfile.birthPlace = location.fullName
                                    editedProfile.birthCoordinates = location.coordinate
                                    editedProfile.timezone = location.timezone
                                }
                                */
                                TextField("City, State/Country", text: Binding(
                                    get: { editedProfile.birthPlace ?? "" },
                                    set: { editedProfile.birthPlace = $0.isEmpty ? nil : $0 }
                                ))
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
    
    @State private var showingReportSheet = false
    @State private var showingReportsLibrary = false
    @State private var selectedReportType: String = ""
    @State private var userReports: [DetailedReport] = []
    @State private var hasSubscription = false
    @EnvironmentObject private var auth: AuthState
    
    private let apiServices = APIServices.shared
    
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
                        // Scroll to Premium Insights section or highlight it
                        withAnimation(.easeInOut(duration: 0.8)) {
                            // This could trigger a scroll or highlight animation
                            // For now, we'll leave this empty as the Premium Insights section is already visible below
                        }
                    }
                )
                
                // Premium Insights Section
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
                
            }
            .padding()
        }
        .onAppear {
            checkSubscriptionStatus()
            loadUserReports()
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
    }
    
    private func checkSubscriptionStatus() {
        hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }
    
    private func loadUserReports() {
        guard let userId = UserDefaults.standard.string(forKey: "apple_user_id") else { return }
        
        Task {
            do {
                let response = try await apiServices.getUserReports(userId: userId)
                await MainActor.run {
                    userReports = response.reports
                }
            } catch {
                print("Failed to load user reports: \(error)")
            }
        }
    }
    
    private func generateReport(reportType: String) {
        guard let userId = UserDefaults.standard.string(forKey: "apple_user_id") else { return }
        
        Task {
            do {
                let birthData = try BirthData(from: auth.profileManager.profile)
                let _ = try await apiServices.generateDetailedReport(
                    birthData: birthData,
                    type: reportType,
                    userId: userId
                )
                
                await MainActor.run {
                    showingReportSheet = false
                    loadUserReports() // Refresh the reports list
                }
            } catch {
                print("Failed to generate report: \(error)")
            }
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
                            Image(systemName: "arrow.right.circle.fill")
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    InsightCard(
                        insight: insight,
                        hasSubscription: hasSubscription,
                        isGenerated: savedReports.contains { $0.type == insight.id },
                        onTap: {
                            onInsightTap(insight.id)
                        }
                    )
                }
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
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if !hasSubscription {
                        if let pricing = ReportPricing.pricing(for: insight.id) {
                            Text(pricing.localizedPrice ?? pricing.price)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(insight.color)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
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
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: reportInfo.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(reportInfo.color)
                    
                    Text(reportInfo.title)
                        .font(.largeTitle.weight(.bold))
                    
                    Text(reportInfo.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    SimpleFeatureRow(icon: "brain.head.profile", text: "AI-powered personalized analysis")
                    SimpleFeatureRow(icon: "clock", text: "Generated in under 60 seconds")
                    SimpleFeatureRow(icon: "arrow.down.circle", text: "PDF download included")
                    SimpleFeatureRow(icon: "bookmark", text: "Saved to your profile forever")
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                
                Spacer()
                
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
                                
                                Text(isGenerating ? "Generating..." : "Generate Report")
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
                        // Individual Purchase Options
                        VStack(spacing: 12) {
                            if let pricing = ReportPricing.pricing(for: reportType) {
                                Button {
                                    purchaseIndividualReport()
                                } label: {
                                    HStack {
                                        Image(systemName: "creditcard.and.123")
                                        VStack(spacing: 4) {
                                            Text("Purchase This Report")
                                                .font(.headline)
                                            Text(pricing.localizedPrice ?? pricing.price)
                                                .font(.title2.weight(.bold))
                                        }
                                        Spacer()
                                        Image(systemName: "apple.logo")
                                            .font(.title2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .foregroundStyle(.white)
                                    .background(reportInfo.color)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button {
                                showingSubscription = true
                            } label: {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Or get Astronova Pro")
                                            .font(.subheadline)
                                        Text("$9.99/month")
                                            .font(.subheadline.weight(.bold))
                                    }
                                    Text("All reports + unlimited chat")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.primary)
                                .background(.quaternary)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Text("All reports are saved to your profile for future reference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
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
    }
    
    private func generateReport() {
        isGenerating = true
        onGenerate(reportType)
    }
    
    private func purchaseIndividualReport() {
        isGenerating = true
        Task {
            let success = await StoreManager.shared.purchaseProduct(productId: reportType)
            await MainActor.run {
                if success {
                    onGenerate(reportType)
                } else {
                    isGenerating = false
                    // TODO: Show error alert
                }
            }
        }
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
        NavigationView {
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
        NavigationView {
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
                            Label("Download PDF", systemImage: "arrow.down.circle")
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
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
        // TODO: Implement PDF download
        Task {
            // TODO: Integrate real download endpoint. For now, just log.
            print("Downloading PDF for report: \(report.reportId)")
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
            PlanetaryCalculationsView()
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
        NavigationView {
            VStack {
                if hasContactsAccess {
                    // Search bar
                    TextField("Search contacts", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
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
        case .denied:
            hasContactsAccess = false
        case .restricted:
            hasContactsAccess = false
        case .notDetermined:
            hasContactsAccess = false
        case .limited:
            hasContactsAccess = false
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
            requestLocationPermission()
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
        ScrollView {
            VStack(spacing: 32) {
                // Immediate cosmic hook
                VStack(spacing: 20) {
                    // Pulsing cosmic symbol
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
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateStars ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateStars)
                        
                        Text("✨")
                            .font(.system(size: 40))
                            .rotationEffect(.degrees(animateStars ? 360 : 0))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateStars)
                    }
                    
                    VStack(spacing: 8) {
                        Text("The universe speaks to you")
                            .font(.title2.weight(.light))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text("Right now")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .padding(.top, 20)
                
                // Live celestial data - show value immediately
                cosmicDataDisplay
                
                // Instant personalized insight
                VStack(spacing: 16) {
                    Text("Your Personal Reading")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text(personalizedInsight.isEmpty ? "The universe recognizes your unique frequency. This moment marks a significant turning point in your spiritual journey - trust the process." : personalizedInsight)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.pink.opacity(0.5), .purple.opacity(0.5), .cyan.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .purple.opacity(0.2), radius: 8, y: 4)
                }
                
                // Single call to action
                VStack(spacing: 12) {
                    Text("Get Your Complete Astrological Profile")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Unlock personalized insights, birth chart analysis, and celestial guidance")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Sign in buttons
                signInButtons
                
                Spacer(minLength: 40)
            }
            .padding()
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

// MARK: - Keyboard Dismiss Functionality

class KeyboardManager: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.isKeyboardVisible = true
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    self?.keyboardHeight = keyboardFrame.height
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = false
                self?.keyboardHeight = 0
            }
            .store(in: &cancellables)
    }
}

struct KeyboardDismissOverlay: View {
    @StateObject private var keyboardManager = KeyboardManager()
    
    var body: some View {
        ZStack {
            if keyboardManager.isKeyboardVisible {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            hideKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .padding(12)
                                .background(.regularMaterial, in: Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboardManager.isKeyboardVisible)
            }
        }
        .allowsHitTesting(keyboardManager.isKeyboardVisible)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func keyboardDismissButton() -> some View {
        self.overlay(KeyboardDismissOverlay())
    }
}

// MARK: - Duplicate Notification Extension Removed

// (Original definitions for `switchToTab` and `switchToProfileSection` exist at
// the top of this file.)
