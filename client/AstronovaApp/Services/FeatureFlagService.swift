import Foundation
import SwiftUI

/// Service to manage feature flags for A/B testing and gradual rollouts
@MainActor
class FeatureFlagService: ObservableObject {
    static let shared = FeatureFlagService()
    
    @Published private(set) var flags: [String: FeatureFlag] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let flagsKey = "com.astronova.featureflags"
    
    private init() {
        loadFlags()
        setupDefaultFlags()
    }
    
    // MARK: - Default Feature Flags
    
    private func setupDefaultFlags() {
        // Define your feature flags here
        let defaultFlags: [FeatureFlag] = [
            FeatureFlag(
                key: "enhanced_animations",
                name: "Enhanced Animations",
                description: "Show enhanced cosmic animations throughout the app",
                defaultValue: true,
                rolloutPercentage: 100
            ),
            FeatureFlag(
                key: "quick_insights",
                name: "Quick Insights",
                description: "Show quick insights on the home screen",
                defaultValue: false,
                rolloutPercentage: 50
            ),
            FeatureFlag(
                key: "premium_trial",
                name: "Premium Trial",
                description: "Offer 7-day premium trial to new users",
                defaultValue: false,
                rolloutPercentage: 25
            ),
            FeatureFlag(
                key: "social_sharing",
                name: "Social Sharing",
                description: "Enable social sharing features",
                defaultValue: true,
                rolloutPercentage: 100
            ),
            FeatureFlag(
                key: "performance_mode",
                name: "Performance Mode",
                description: "Enable performance optimizations",
                defaultValue: true,
                rolloutPercentage: 100
            ),
            FeatureFlag(
                key: "new_onboarding",
                name: "New Onboarding Flow",
                description: "Test new onboarding experience",
                defaultValue: false,
                rolloutPercentage: 10
            )
        ]
        
        // Add default flags if they don't exist
        for flag in defaultFlags {
            if flags[flag.key] == nil {
                flags[flag.key] = flag
            }
        }
        
        saveFlags()
    }
    
    // MARK: - Public API
    
    /// Check if a feature flag is enabled
    func isEnabled(_ key: String) -> Bool {
        guard let flag = flags[key] else {
            return false
        }
        
        // Check override first
        if let override = flag.overrideValue {
            return override
        }
        
        // Check rollout percentage
        if flag.rolloutPercentage < 100 {
            let userHash = getUserHash(for: key)
            return userHash < flag.rolloutPercentage
        }
        
        return flag.defaultValue
    }
    
    /// Get a feature flag by key
    func flag(for key: String) -> FeatureFlag? {
        flags[key]
    }
    
    /// Override a feature flag value (for testing)
    func override(_ key: String, value: Bool?) {
        guard var flag = flags[key] else { return }
        flag.overrideValue = value
        flags[key] = flag
        saveFlags()
    }
    
    /// Reset all overrides
    func resetOverrides() {
        for key in flags.keys {
            flags[key]?.overrideValue = nil
        }
        saveFlags()
    }
    
    /// Get all available feature flags
    var allFlags: [FeatureFlag] {
        Array(flags.values).sorted { $0.name < $1.name }
    }
    
    // MARK: - Private Methods
    
    private func getUserHash(for flagKey: String) -> Int {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let combined = "\(deviceId)-\(flagKey)"
        
        var hash = 0
        for char in combined {
            hash = ((hash << 5) &- hash) &+ Int(char.asciiValue ?? 0)
        }
        
        return abs(hash) % 100
    }
    
    private func loadFlags() {
        if let data = userDefaults.data(forKey: flagsKey),
           let decoded = try? JSONDecoder().decode([String: FeatureFlag].self, from: data) {
            flags = decoded
        }
    }
    
    private func saveFlags() {
        if let encoded = try? JSONEncoder().encode(flags) {
            userDefaults.set(encoded, forKey: flagsKey)
        }
    }
}

// MARK: - Feature Flag Model

struct FeatureFlag: Codable, Identifiable {
    let key: String
    let name: String
    let description: String
    let defaultValue: Bool
    let rolloutPercentage: Int
    var overrideValue: Bool?
    
    var id: String { key }
    
    var effectiveValue: Bool {
        overrideValue ?? defaultValue
    }
}

// MARK: - View Modifier for Feature Flags

struct FeatureFlagModifier: ViewModifier {
    let flag: String
    let enabledContent: () -> AnyView
    let disabledContent: () -> AnyView
    
    @ObservedObject private var featureFlags = FeatureFlagService.shared
    
    func body(content: Content) -> some View {
        Group {
            if featureFlags.isEnabled(flag) {
                enabledContent()
            } else {
                disabledContent()
            }
        }
    }
}

extension View {
    /// Conditionally show content based on feature flag
    func featureFlag(
        _ flag: String,
        @ViewBuilder enabled: @escaping () -> some View = { EmptyView() },
        @ViewBuilder disabled: @escaping () -> some View = { EmptyView() }
    ) -> some View {
        modifier(FeatureFlagModifier(
            flag: flag,
            enabledContent: { AnyView(enabled()) },
            disabledContent: { AnyView(disabled()) }
        ))
    }
    
    /// Show view only if feature flag is enabled
    @ViewBuilder
    func showIfEnabled(_ flag: String) -> some View {
        if FeatureFlagService.shared.isEnabled(flag) {
            self
        }
    }
}

// MARK: - Debug View for Feature Flags

#if DEBUG
struct FeatureFlagsDebugView: View {
    @ObservedObject private var service = FeatureFlagService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Feature flags allow you to test new features with a subset of users")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Active Flags") {
                    ForEach(service.allFlags) { flag in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(flag.name)
                                        .font(.headline)
                                    Text(flag.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { flag.overrideValue ?? service.isEnabled(flag.key) },
                                    set: { service.override(flag.key, value: $0) }
                                ))
                            }
                            
                            HStack {
                                Label("\(flag.rolloutPercentage)% rollout", systemImage: "person.3.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if flag.overrideValue != nil {
                                    Label("Overridden", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Feature Flags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        service.resetOverrides()
                    }
                }
            }
        }
    }
}

#Preview {
    FeatureFlagsDebugView()
}
#endif