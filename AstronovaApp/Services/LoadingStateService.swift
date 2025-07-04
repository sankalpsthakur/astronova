import SwiftUI
import Combine

/// Service to manage immediate loading state display across the app
@MainActor
class LoadingStateService: ObservableObject {
    static let shared = LoadingStateService()
    
    @Published private(set) var isLoading = false
    @Published private(set) var loadingMessage: String?
    
    private var loadingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Shows loading state immediately without any delay
    func showLoading(message: String? = nil) {
        // Cancel any pending hide operations
        loadingTimer?.invalidate()
        loadingTimer = nil
        
        // Show loading state immediately
        isLoading = true
        loadingMessage = message
        
        // Haptic feedback for loading start
        HapticFeedbackService.shared.lightImpact()
    }
    
    /// Hides loading state with optional minimum display time
    func hideLoading(minimumDisplayTime: TimeInterval = 0.3) {
        let timeShown = Date().timeIntervalSince(Date())
        
        if timeShown < minimumDisplayTime {
            // Ensure loading is shown for at least minimum time
            let remainingTime = minimumDisplayTime - timeShown
            loadingTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { _ in
                Task { @MainActor in
                    self.isLoading = false
                    self.loadingMessage = nil
                }
            }
        } else {
            // Hide immediately
            isLoading = false
            loadingMessage = nil
        }
        
        // Haptic feedback for loading complete
        HapticFeedbackService.shared.success()
    }
    
    /// Performs an async operation with automatic loading state management
    func withLoading<T>(
        message: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        showLoading(message: message)
        
        do {
            let result = try await operation()
            hideLoading()
            return result
        } catch {
            hideLoading()
            throw error
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds an overlay loading indicator that appears immediately
    func immediateLoadingOverlay(isLoading: Binding<Bool>, message: String? = nil) -> some View {
        overlay(
            Group {
                if isLoading.wrappedValue {
                    ImmediateLoadingOverlay(message: message)
                        .transition(.opacity.animation(.linear(duration: 0.05)))
                }
            }
        )
    }
    
    /// Automatically shows loading state for async button actions
    func loadingButton<T>(
        message: String? = nil,
        action: @escaping () async throws -> T
    ) -> some View {
        onTapGesture {
            Task {
                try? await LoadingStateService.shared.withLoading(
                    message: message,
                    operation: action
                )
            }
        }
    }
}

// MARK: - Immediate Loading Overlay

struct ImmediateLoadingOverlay: View {
    let message: String?
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                if let message = message {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(radius: 10)
            )
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            // Immediate appearance without animation delay
            isVisible = true
        }
    }
}