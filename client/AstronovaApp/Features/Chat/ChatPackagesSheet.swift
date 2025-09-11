import SwiftUI

struct ChatPackagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @State private var isPurchasing: String? = nil
    
    private let packs: [ShopCatalog.ChatPack] = ShopCatalog.chatPacks
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Ask Packages")
                        .font(.title.bold())
                    Text("Buy reply credits to use anytime. No subscription.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.blue)
                    Text("Available credits: \(chatCredits)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                List {
                    ForEach(packs) { pack in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pack.title).font(.headline)
                                Text(pack.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task { await buy(pack) }
                            } label: {
                                HStack(spacing: 6) {
                                    if isPurchasing == pack.productId { ProgressView().tint(.white) }
                                    Text(isPurchasing == pack.productId ? "Processing…" : ShopCatalog.price(for: pack.productId))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isPurchasing != nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Chat Packages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func buy(_ pack: ShopCatalog.ChatPack) async {
        guard isPurchasing == nil else { return }
        isPurchasing = pack.productId
        defer { isPurchasing = nil }
        let ok = await BasicStoreManager.shared.purchaseProduct(productId: pack.productId)
        if ok {
            // chatCredits updates in store manager; here we just keep UI fresh
        }
    }
}
