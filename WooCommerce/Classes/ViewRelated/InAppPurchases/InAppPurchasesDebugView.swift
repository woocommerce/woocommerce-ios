import SwiftUI
import StoreKit
import Yosemite

@MainActor
struct InAppPurchasesDebugView: View {
    let siteID: Int64
    private let inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
    @State var products: [WPComPlanProduct] = []

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
                        Button(product.description) {
                            Task {
                                try? await inAppPurchasesForWPComPlansManager.purchaseProduct(with: product.id, for: siteID)
                            }
                        }
                    }
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
            } catch {
                print("Error loading products: \(error)")
            }
        }
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView(siteID: 0)
    }
}
