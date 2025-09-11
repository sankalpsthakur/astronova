import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Unlock Everything")
                .font(.largeTitle.bold())
            Text("Unlimited chat + all detailed reports.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Unlimited Ask (AI chat)", systemImage: "bubble.left.and.bubble.right.fill")
                Label("All detailed reports included", systemImage: "doc.text.fill")
                Label("Love, Career, Money, Health + more", systemImage: "sparkles")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Analytics.shared.track(.paywallShown, properties: ["variant": RemoteConfigService.shared.string(forKey: "paywall_variant", default: "A")])
                Task { await purchasePro() }
            } label: {
                HStack {
                    if isPurchasing { ProgressView().tint(.white) }
                    Text(isPurchasing ? "Purchasing..." : "Start Pro for $9.99/mo")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)

            // Alternative CTAs
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    triggerShowReportShop = true
                    NotificationCenter.default.post(name: .switchToTab, object: 0)
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Buy a detailed report (from $12.99)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    triggerShowChatPackages = true
                    NotificationCenter.default.post(name: .switchToTab, object: 3)
                } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Get chat packages (no subscription)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func purchasePro() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        let success = await BasicStoreManager.shared.purchaseProduct(productId: "astronova_pro_monthly")
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
