import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var guidance: DailyGuidance?
    @Published var recent: [DailyGuidance] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showPaywall = false
    @Published var showShare = false

    private let guidanceService = HomeGuidanceService.shared
    private let profileManager: UserProfileManager
    private let store: StoreManagerProtocol

    init(profileManager: UserProfileManager, store: StoreManagerProtocol = DependencyContainer.shared.storeManager) {
        self.profileManager = profileManager
        self.store = store
    }

    func load() async {
        guard let sign = sunSign() else { return }
        isLoading = true; error = nil
        do {
            let g = try await guidanceService.loadGuidance(sign: sign)
            guidance = g
            recent = guidanceService.recentGuidance(sign: sign)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func sunSign() -> String? {
        if let s = profileManager.profile.sunSign, !s.isEmpty { return s }
        return Zodiac.sign(for: profileManager.profile.birthDate)
    }

    func triggerPaywallIfLocked() {
        // Simple gating: if Pro not active, show paywall when expanding tile details
        if !store.hasProSubscription {
            showPaywall = true
            Analytics.shared.track(.paywallShown, properties: ["trigger": "home_tile_expand"])
        }
    }
}
