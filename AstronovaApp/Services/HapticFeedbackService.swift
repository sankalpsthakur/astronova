import UIKit
import SwiftUI

/// Centralized haptic feedback service for consistent tactile experiences
class HapticFeedbackService {
    static let shared = HapticFeedbackService()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions (button taps, small selections)
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium impact for standard interactions (navigation, confirmations)
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Heavy impact for significant actions (important confirmations, errors)
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback for positive outcomes
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning feedback for caution situations
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error feedback for negative outcomes
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker changes, list selections
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Cosmic-themed Feedback Patterns
    
    /// Mystical pattern for cosmic events and insights
    func cosmicInsight() {
        DispatchQueue.main.async {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.lightImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.mediumImpact()
                }
            }
        }
    }
    
    /// Celebration pattern for achievements and positive events
    func celebration() {
        DispatchQueue.main.async {
            self.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.lightImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.lightImpact()
                }
            }
        }
    }
    
    /// Starburst pattern for special animations
    func starburst() {
        DispatchQueue.main.async {
            self.mediumImpact()
            for i in 1...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    self.lightImpact()
                }
            }
        }
    }
    
    /// Gentle wave pattern for transitions
    func transition() {
        DispatchQueue.main.async {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.lightImpact()
            }
        }
    }
    
    // MARK: - Contextual Feedback
    
    /// Feedback for navigation between tabs
    func tabNavigation() {
        mediumImpact()
    }
    
    /// Feedback for sign-in success
    func signInSuccess() {
        celebration()
    }
    
    /// Feedback for loading completion
    func loadingComplete() {
        success()
    }
    
    /// Feedback for compatibility match
    func compatibilityMatch() {
        cosmicInsight()
    }
    
    /// Feedback for horoscope reveal
    func horoscopeReveal() {
        starburst()
    }
    
    /// Feedback for phase transitions in onboarding
    func phaseTransition() {
        transition()
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Adds haptic feedback on tap gesture
    func hapticFeedback(_ type: HapticFeedbackType = .light) -> some View {
        onTapGesture {
            switch type {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            case .selection:
                HapticFeedbackService.shared.selection()
            case .cosmic:
                HapticFeedbackService.shared.cosmicInsight()
            case .celebration:
                HapticFeedbackService.shared.celebration()
            case .starburst:
                HapticFeedbackService.shared.starburst()
            }
        }
    }
    
    /// Adds haptic feedback with custom action
    func hapticFeedback(_ type: HapticFeedbackType = .light, action: @escaping () -> Void) -> some View {
        onTapGesture {
            switch type {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            case .selection:
                HapticFeedbackService.shared.selection()
            case .cosmic:
                HapticFeedbackService.shared.cosmicInsight()
            case .celebration:
                HapticFeedbackService.shared.celebration()
            case .starburst:
                HapticFeedbackService.shared.starburst()
            }
            action()
        }
    }
}

// MARK: - Haptic Feedback Types

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    case cosmic
    case celebration
    case starburst
}