import SwiftUI
import CommerceKit
import DataModels

/// Grid of products with Apple Pay checkout.
struct ShopView: View {
    @StateObject private var repo = ProductRepository()
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(repo.products) { product in
                        ProductCard(product: product) {
                            purchase(product)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shop")
        }
        .task { await repo.refresh() }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to complete purchase.")
        }
    }

    private func purchase(_ product: Product) {
        ApplePayHandler().startPayment(for: product)
    }
}

#if canImport(UIKit)
private struct ProductCard: View {
    let product: Product
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Placeholder image – in production we would load CKAsset.
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .frame(height: 100)
                .overlay(Text("📦"))
            Text(product.name)
                .font(.subheadline)
                .lineLimit(1)
            Text("$\(product.price, specifier: "%.2f")")
                .font(.footnote.weight(.bold))
            Button("Buy", action: onTap)
                .applyProminentButtonStyle()
                .font(.footnote)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(radius: 2)
    }
}

private extension View {
    @ViewBuilder
    func applyProminentButtonStyle() -> some View {
        if #available(iOS 15.0, *) {
            self.buttonStyle(.borderedProminent)
        } else {
            self
        }
    }
}
#endif
