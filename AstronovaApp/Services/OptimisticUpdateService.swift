import SwiftUI
import Combine

/// Service to manage optimistic UI updates for better perceived performance
@MainActor
class OptimisticUpdateService: ObservableObject {
    static let shared = OptimisticUpdateService()
    
    @Published private(set) var pendingUpdates: [String: Any] = [:]
    private var rollbackData: [String: Any] = [:]
    
    private init() {}
    
    /// Apply an optimistic update immediately while the actual request is in progress
    func applyOptimisticUpdate<T>(
        key: String,
        currentValue: T,
        newValue: T,
        update: @escaping () async throws -> Void
    ) async throws {
        // Store rollback data
        rollbackData[key] = currentValue
        pendingUpdates[key] = newValue
        
        // Apply the update immediately
        HapticFeedbackService.shared.lightImpact()
        
        do {
            // Perform the actual update
            try await update()
            
            // Success - remove from pending
            pendingUpdates.removeValue(forKey: key)
            rollbackData.removeValue(forKey: key)
            
            // Success feedback
            HapticFeedbackService.shared.success()
        } catch {
            // Rollback on failure
            pendingUpdates.removeValue(forKey: key)
            rollbackData.removeValue(forKey: key)
            
            // Error feedback
            HapticFeedbackService.shared.error()
            
            throw error
        }
    }
    
    /// Check if there's a pending optimistic update for a key
    func hasPendingUpdate(for key: String) -> Bool {
        pendingUpdates[key] != nil
    }
    
    /// Get the optimistic value if available, otherwise return the current value
    func optimisticValue<T>(for key: String, current: T) -> T {
        if let pending = pendingUpdates[key] as? T {
            return pending
        }
        return current
    }
}

// MARK: - View Extensions for Optimistic Updates

extension View {
    /// Apply optimistic styling to indicate pending updates
    func optimisticOverlay(isPending: Bool) -> some View {
        overlay(
            Group {
                if isPending {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                        .background(
                            Color.accentColor.opacity(0.05)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: isPending)
    }
    
    /// Apply optimistic opacity for pending items
    func optimisticOpacity(isPending: Bool) -> some View {
        opacity(isPending ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPending)
    }
}

// MARK: - Optimistic State Property Wrapper

@propertyWrapper
struct OptimisticState<Value> {
    private let key: String
    private var value: Value
    private let service = OptimisticUpdateService.shared
    
    init(wrappedValue: Value, key: String) {
        self.key = key
        self.value = wrappedValue
    }
    
    var wrappedValue: Value {
        get {
            service.optimisticValue(for: key, current: value)
        }
        set {
            value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { value = $0 }
        )
    }
}

// MARK: - Example Usage in Views

struct OptimisticToggleExample: View {
    @State private var isEnabled = false
    @StateObject private var optimistic = OptimisticUpdateService.shared
    
    var body: some View {
        Toggle("Feature", isOn: $isEnabled)
            .optimisticOverlay(isPending: optimistic.hasPendingUpdate(for: "feature_toggle"))
            .onChange(of: isEnabled) { _, newValue in
                Task {
                    try await optimistic.applyOptimisticUpdate(
                        key: "feature_toggle",
                        currentValue: !newValue,
                        newValue: newValue
                    ) {
                        // Simulate API call
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        // API call would go here
                    }
                }
            }
    }
}

// MARK: - List Item Optimistic Updates

struct OptimisticListItem: View {
    let item: String
    let onDelete: () async throws -> Void
    
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Text(item)
                .optimisticOpacity(isPending: isDeleting)
            
            Spacer()
            
            if isDeleting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await onDelete()
                    } catch {
                        isDeleting = false
                    }
                }
            }
        }
    }
}