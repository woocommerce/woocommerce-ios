import SwiftUI
import StoreKit
import Yosemite

@MainActor
struct InAppPurchasesDebugView: View {
    let siteID: Int64
    private let inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
    @State var products: [WPComPlanProduct] = []
    @State var entitledProductIDs: [String] = []

    var body: some View {
        List {
            Section {
                Button("Reload products") {
                    loadProducts()
                }
            }
            Section("Products") {
                if products.isEmpty {
                    Text("No products")
                } else {
                    ForEach(products, id: \.id) { product in
                        Button(entitledProductIDs.contains(product.id) ? "Entitled: \(product.description)" : product.description) {
                            Task {
                                try? await inAppPurchasesForWPComPlansManager.purchaseProduct(with: product.id, for: siteID)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Retry WPCom Synchronization for entitled products") {
                    retryWPComSynchronizationForPurchasedProducts()
                }
            }
        }
        .navigationTitle("IAP Debug")
        .onAppear {
            loadProducts()
        }
    }

    private func loadProducts() {
        Task {
            do {
                self.products = try await inAppPurchasesForWPComPlansManager.fetchProducts()
                for product in self.products {
                    if try await inAppPurchasesForWPComPlansManager.userIsEntitledToProduct(with: product.id) {
                        self.entitledProductIDs.append(product.id)
                    }
                }
            } catch {
                print("Error loading products: \(error)")
            }
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
