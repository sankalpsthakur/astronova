import SwiftUI
import CoreLocation

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
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            
            if !showingPersonalizedInsight {
                // Beautiful action button
                VStack(spacing: 16) {
                    Button {
                        handleContinue()
                    } label: {
                        HStack {
                            if currentStep == totalSteps - 1 {
                                Image(systemName: "star.circle.fill")
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