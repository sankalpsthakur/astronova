import SwiftUI
import StoreKit

/// Test view for StoreKit 2 integration
struct StoreKitTestView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("StoreKit 2 Integration Test")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Subscription Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subscription Status")
                        .font(.headline)
                    
                    HStack {
                        Text("Pro Subscription:")
                        Spacer()
                        Text(storeManager.hasProSubscription ? "Active" : "Inactive")
                            .foregroundColor(storeManager.hasProSubscription ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Products
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Products")
                        .font(.headline)
                    
                    if storeManager.products.isEmpty {
                        Text("Loading products...")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(storeManager.products.keys.sorted()), id: \.self) { productId in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(productId.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.subheadline)
                                    Text(storeManager.products[productId] ?? "N/A")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        isLoading = true
                                        let success = await storeManager.purchaseProduct(productId: productId)
                                        isLoading = false
                                        print("Purchase \(productId): \(success ? "Success" : "Failed")")
                                    }
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Buy")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .cornerRadius(6)
                                    }
                                }
                                .disabled(isLoading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Actions
                VStack(spacing: 12) {
                    Button("Refresh Products") {
                        Task {
                            await storeManager.loadProducts()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("StoreKit Test")
        }
        .onAppear {
            Task {
                await storeManager.loadProducts()
            }
        }
    }
}

#Preview {
    StoreKitTestView()
}