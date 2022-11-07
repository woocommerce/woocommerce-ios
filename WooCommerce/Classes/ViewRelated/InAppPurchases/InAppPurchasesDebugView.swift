import SwiftUI
import StoreKit
import Yosemite

@MainActor
struct InAppPurchasesDebugView: View {
    let siteID: Int64
    private let inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
    @State var products: [WPComPlanProduct] = []
    @State var entitledProductIDs: [String] = []
    @State var inAppPurchasesAreSupported = true
    @State var isPurchasing = false

    var body: some View {
        List {
            Section {
                Button("Reload products") {
                    Task {
                        await loadProducts()
                    }
                }
            }
            Section("Products") {
                if products.isEmpty {
                    Text("No products")
                } else if isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(products, id: \.id) { product in
                        Button(entitledProductIDs.contains(product.id) ? "Entitled: \(product.description)" : product.description) {
                            Task {
                                isPurchasing = true
                                try? await inAppPurchasesForWPComPlansManager.purchaseProduct(with: product.id, for: siteID)
                                isPurchasing = false
                            }
                        }
                    }
                }
            }

            Section {
                Button("Retry WPCom Synchronization for entitled products") {
                    retryWPComSynchronizationForPurchasedProducts()
                }.disabled(!inAppPurchasesAreSupported || entitledProductIDs.isEmpty)
            }

            if !inAppPurchasesAreSupported {
                Section {
                    Text("In-App Purchases are not supported for this user")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("IAP Debug")
        .task {
            await loadProducts()
        }
    }

    private func loadProducts() async {
        do {
            inAppPurchasesAreSupported = await inAppPurchasesForWPComPlansManager.inAppPurchasesAreSupported()

            guard inAppPurchasesAreSupported else {
                return
            }

            self.products = try await inAppPurchasesForWPComPlansManager.fetchProducts()
            await loadUserEntitlements()
        } catch {
            print("Error loading products: \(error)")
        }
    }

    private func loadUserEntitlements() async {
        do {
            for product in self.products {
                if try await inAppPurchasesForWPComPlansManager.userIsEntitledToProduct(with: product.id) {
                    self.entitledProductIDs.append(product.id)
                }
            }
        }
        catch {
            print("Error loading user entitlements: \(error)")
        }
    }

    private func retryWPComSynchronizationForPurchasedProducts() {
        Task {
            for id in entitledProductIDs {
                try await inAppPurchasesForWPComPlansManager.retryWPComSyncForPurchasedProduct(with: id)
            }
        }
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView(siteID: 0)
    }
}
