import SwiftUI

enum PaywallVariantAssignment {
    static let key = "paywall_variant"
    static let legacyKey = "astronova_paywall_v1"

    static func normalized(_ rawValue: String) -> String {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "tiered_v1", "b":
            return "tiered_v1"
        case "tiered_v2", "c":
            return "tiered_v2"
        default:
            return "control"
        }
    }

    static func resolvedVariant() -> String {
        if RemoteConfigService.shared.hasValue(forKey: key) {
            return normalized(RemoteConfigService.shared.string(forKey: key, default: "control"))
        }
        return normalized(RemoteConfigService.shared.string(forKey: legacyKey, default: "control"))
    }
}

/// Renders the paywall variant assigned to this user for the canonical
/// `paywall_variant` experiment. Wire this in at every existing
/// `PaywallView()` call site:
///
/// ```swift
/// .sheet(isPresented: $showPaywall) {
///     PaywallVariantRouter(context: .chatLimit)
/// }
/// ```
///
/// The router is intentionally dumb — it resolves the variant string once on
/// appear and forwards to the matching SwiftUI view. Exposure logging and
/// bucket tagging are handled by `IOSAppsExperiments.assign(...)` when the
/// package is wired in (Wave 13 agent #8). Until then, the local resolver
/// reads from `RemoteConfigService` so the experiment is still active during
/// rollout.
struct PaywallVariantRouter: View {
    let context: PaywallContext

    init(context: PaywallContext = .general) {
        self.context = context
    }

    /// The variant string assigned to this user. Resolution priority:
    ///   1. `IOSAppsExperiments.shared.assign(...)` once linked.
    ///   2. `RemoteConfigService.string(forKey: "paywall_variant")`.
    ///   3. legacy `astronova_paywall_v1`, if the canonical key is absent.
    ///   4. `"control"`.
    private var variant: String {
        // TODO: replace with IOSAppsExperiments.shared.assign(...) once the
        // package is added as a Swift Package dependency to AstronovaApp.
        PaywallVariantAssignment.resolvedVariant()
    }

    var body: some View {
        switch variant {
        case "tiered_v1":
            PaywallVariant_TieredV1(context: context)
        case "tiered_v2":
            PaywallVariant_TieredV2(context: context)
        default:
            PaywallView(context: context)
        }
    }
}
