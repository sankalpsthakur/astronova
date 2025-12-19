import UIKit
import SwiftUI
import CoreHaptics

/// Centralized haptic feedback service for consistent tactile experiences
class HapticFeedbackService {
    static let shared = HapticFeedbackService()

    private init() {}

    // MARK: - Hardware Support Check

    /// Check if the device supports haptics
    private var supportsHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    // MARK: - Impact Feedback

    /// Light impact for subtle interactions (button taps, small selections)
    func lightImpact() {
        guard supportsHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    /// Medium impact for standard interactions (navigation, confirmations)
    func mediumImpact() {
        guard supportsHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    /// Heavy impact for significant actions (important confirmations, errors)
    func heavyImpact() {
        guard supportsHaptics else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback

    /// Success feedback for positive outcomes
    func success() {
        guard supportsHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    /// Warning feedback for caution situations
    func warning() {
        guard supportsHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }

    /// Error feedback for negative outcomes
    func error() {
        guard supportsHaptics else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback

    /// Selection feedback for picker changes, list selections
    func selection() {
        guard supportsHaptics else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Cosmic-themed Feedback Patterns
    
    /// Mystical pattern for cosmic events and insights
    func cosmicInsight() {
        // Single medium impact for immediate feedback
        mediumImpact()
    }
    
    /// Celebration pattern for achievements and positive events
    func celebration() {
        // Single success notification for immediate feedback
        success()
    }
    
    /// Starburst pattern for special animations
    func starburst() {
        // Single heavy impact for immediate feedback
        heavyImpact()
    }
    
    /// Gentle wave pattern for transitions
    func transition() {
        // Single light impact for immediate feedback
        lightImpact()
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