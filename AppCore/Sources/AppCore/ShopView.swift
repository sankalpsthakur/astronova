import SwiftUI
import CommerceKit
import DataModels

/// Grid of products for display only.
struct ShopView: View {
    @StateObject private var repo = ProductRepository()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(repo.products) { product in
                        ProductCard(product: product)
                    }
                }
                .padding()
            }
            .navigationTitle("Shop")
        }
        .task { await repo.refresh() }
    }
}

#if canImport(UIKit)
private struct ProductCard: View {
    let product: Product

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
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(radius: 2)
    }
}

#endif
