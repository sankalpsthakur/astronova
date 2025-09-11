import SwiftUI

struct ReportsStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @State private var isPurchasing: String? = nil
    @State private var purchaseMessage: String? = nil
    
    private let offers: [ShopCatalog.Report] = ShopCatalog.reports
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header copy focused on conversion
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detailed Reports")
                            .font(.largeTitle.bold())
                        Text("Crystal‑clear guidance for the area you care about most.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(offers) { offer in
                            ReportOfferRow(
                                offer: offer,
                                isPurchasing: isPurchasing == offer.productId,
                                price: ShopCatalog.price(for: offer.productId),
                                onPurchase: { Task { await purchase(offer) } }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    if let msg = purchaseMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Reports Shop")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func purchase(_ offer: ShopCatalog.Report) async {
        guard isPurchasing == nil else { return }
        isPurchasing = offer.productId
        defer { isPurchasing = nil }
        
        let ok = await BasicStoreManager.shared.purchaseProduct(productId: offer.productId)
        if ok {
            // Attempt to generate the report immediately if possible
            do {
                let profile = auth.profileManager.profile
                let birthData = try BirthData(from: profile)
                _ = try await APIServices.shared.generateReport(birthData: birthData, type: mapReportType(offer.id))
                await MainActor.run {
                    purchaseMessage = "Purchased • Your \(offer.title) is being generated."
                }
            } catch {
                await MainActor.run {
                    purchaseMessage = "Purchased • You can generate your \(offer.title) from Home."
                }
            }
        }
    }
    
    private func mapReportType(_ id: String) -> String {
        switch id {
        case "general": return "birth_chart"
        case "love": return "love_forecast"
        case "career": return "career_forecast"
        case "money": return "year_ahead" // placeholder mapping
        case "health": return "year_ahead"
        case "family": return "year_ahead"
        case "spiritual": return "year_ahead"
        default: return id
        }
    }
}

private struct ReportOfferRow: View {
    let offer: ShopCatalog.Report
    let isPurchasing: Bool
    let price: String
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(offer.color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: offer.icon)
                    .foregroundStyle(offer.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(offer.title).font(.headline)
                Text(offer.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onPurchase) {
                HStack(spacing: 6) {
                    if isPurchasing { ProgressView().tint(.white) }
                    Text(isPurchasing ? "Processing…" : price)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.quaternary)
        .cornerRadius(12)
    }
}
