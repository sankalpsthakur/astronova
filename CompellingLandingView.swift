import SwiftUI
import AuthenticationServices
import CoreLocation

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
    @Namespace private var cosmicElements
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Dynamic Cosmic Background
            cosmicBackground
            
            VStack(spacing: 0) {
                switch currentPhase {
                case 0:
                    cosmicHookPhase
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case 1:
                    celestialMomentPhase
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case 2:
                    personalizedInsightPhase
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                default:
                    signInPhase
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateCosmicData()
        }
        .onAppear {
            startCosmicJourney()
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
    
    // MARK: - Phase 1: Cosmic Hook
    
    private var cosmicHookPhase: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                // Pulsing cosmic symbol with matched geometry
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateStars ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateStars)
                        .matchedGeometryEffect(id: "cosmicAura", in: cosmicElements)
                    
                    Text("✨")
                        .font(.system(size: 60))
                        .rotationEffect(.degrees(animateStars ? 360 : 0))
                        .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateStars)
                        .matchedGeometryEffect(id: "mainCosmicSymbol", in: cosmicElements)
                }
                
                VStack(spacing: 12) {
                    Text("The cosmos has been waiting")
                        .font(.title.weight(.light))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("for this exact moment")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                }
                .opacity(currentPhase >= 0 ? 1 : 0)
                .animation(.easeInOut(duration: 1).delay(0.5), value: currentPhase)
            }
            
            VStack(spacing: 16) {
                Text(formatCurrentTime())
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("Your cosmic signature is forming...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(currentPhase >= 0 ? 1 : 0)
                    .animation(.easeInOut(duration: 1).delay(1.5), value: currentPhase)
            }
            
            Spacer()
            
            // Tap to continue
            Button {
                HapticFeedbackService.shared.phaseTransition()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.5)) {
                    currentPhase = 1
                }
            } label: {
                HStack(spacing: 12) {
                    Text("Reveal Your Cosmic Moment")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.headline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
            }
            .opacity(currentPhase >= 0 ? 1 : 0)
            .animation(.easeInOut(duration: 1).delay(2), value: currentPhase)
            .overlay(
                StarburstAnimationView(style: .cosmic, duration: 1.5, particleCount: 15)
                    .opacity(currentPhase == 1 ? 1 : 0)
                    .allowsHitTesting(false)
            )
            
            Spacer(minLength: 50)
        }
        .padding()
    }
    
    // MARK: - Phase 2: Celestial Moment
    
    private var celestialMomentPhase: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Right Now")
                    .font(.title3.weight(.light))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("The Universe Speaks")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .matchedGeometryEffect(id: "mainCosmicSymbol", in: cosmicElements)
            }
            
            // Live cosmic data display
            cosmicDataDisplay
            
            Button {
                HapticFeedbackService.shared.horoscopeReveal()
                generatePersonalizedInsight()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.5)) {
                    currentPhase = 2
                }
            } label: {
                HStack(spacing: 12) {
                    Text("What Does This Mean For Me?")
                    Image(systemName: "sparkles")
                }
                .font(.headline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .cyan.opacity(0.3), radius: 10, y: 5)
            }
            
            Spacer()
        }
        .padding()
        .opacity(currentPhase >= 1 ? 1 : 0)
        .animation(.easeInOut(duration: 1), value: currentPhase)
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
            
            // Cosmic coordinates
            if let location = userLocation {
                VStack(spacing: 8) {
                    Text("Your Cosmic Coordinates")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white)
                    
                    Text("\(location.coordinate.latitude, specifier: "%.2f")°N, \(location.coordinate.longitude, specifier: "%.2f")°W")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.cyan)
                    
                    Text("Celestial alignment detected")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                )
            } else {
                // Show button to get cosmic coordinates
                Button {
                    requestLocationPermission()
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "location.circle")
                                .font(.title2)
                            Text("Get My Cosmic Coordinates")
                                .font(.headline.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        
                        Text("Discover your unique celestial alignment")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .opacity(showCelestialData ? 1 : 0)
        .animation(.easeInOut(duration: 1).delay(0.5), value: showCelestialData)
        .onAppear {
            showCelestialData = true
        }
    }
    
    // MARK: - Phase 3: Personalized Insight
    
    private var personalizedInsightPhase: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Your Cosmic Reading")
                    .font(.title2.weight(.light))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("✨ Personally Channeled ✨")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
            }
            
            // Personalized insight card
            VStack(spacing: 20) {
                Text(personalizedInsight)
                    .font(.title3.weight(.medium))
                    .lineSpacing(6)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.pink.opacity(0.5), .purple.opacity(0.5), .cyan.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 15, y: 8)
                
                Text("This is just the beginning of your cosmic journey...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Sign in to unlock more
            VStack(spacing: 16) {
                Text("Unlock Your Complete Cosmic Profile")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                signInButtons
            }
            
            Spacer(minLength: 30)
        }
        .padding()
        .opacity(currentPhase >= 2 ? 1 : 0)
        .animation(.easeInOut(duration: 1), value: currentPhase)
    }
    
    // MARK: - Sign In Phase
    
    private var signInPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("🌌")
                    .font(.system(size: 80))
                
                Text("Welcome to Astronova")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Your personalized cosmic companion")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            signInButtons
            
            Spacer(minLength: 32)
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
                        LoadingView(style: .inline, message: "Connecting to the cosmos...")
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
            do {
                // Try to get dynamic insights from ContentManagementService
                let insights = try await ContentManagementService.shared.getInsights()
                let landingInsights = insights.filter { $0.category == "landing" || $0.category == "daily" }
                
                if let dynamicInsight = landingInsights.randomElement() {
                    await MainActor.run {
                        personalizedInsight = dynamicInsight.content
                    }
                    return
                }
            } catch {
                print("Failed to load dynamic insights: \(error)")
            }
            
            // Fallback to static insights
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
                HapticFeedbackService.shared.signInSuccess()
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

// Preview
#Preview {
    CompellingLandingView()
        .environmentObject(AuthState())
}