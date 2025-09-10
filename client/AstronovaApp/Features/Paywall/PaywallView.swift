import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Astronova Pro")
                .font(.largeTitle.bold())
            Text("Unlock deeper insights, compatibility, and more.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Year-ahead reports", systemImage: "calendar.badge.plus")
                Label("Compatibility insights", systemImage: "heart.circle")
                Label("Saved profiles", systemImage: "person.2.circle")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Analytics.shared.track(.paywallShown, properties: ["variant": RemoteConfigService.shared.string(forKey: "paywall_variant", default: "A")])
                Task { await purchasePro() }
            } label: {
                HStack {
                    if isPurchasing { ProgressView().tint(.white) }
                    Text(isPurchasing ? "Purchasing..." : "Go Pro")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func purchasePro() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        let success = await StoreKitManager.shared.purchaseProduct(productId: "astronova_pro_monthly")
        isPurchasing = false
        if success {
            Analytics.shared.track(.purchaseSuccess, properties: ["product": "astronova_pro_monthly"]) 
            dismiss()
        }
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
#endif
