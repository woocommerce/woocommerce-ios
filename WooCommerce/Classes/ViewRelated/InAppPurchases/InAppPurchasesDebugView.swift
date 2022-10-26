import SwiftUI
import StoreKit
import Yosemite

struct InAppPurchasesDebugView: View {
    let siteID: Int64
    private let stores = ServiceLocator.stores
    @State var products: [StoreKit.Product] = []

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
                    ForEach(products) { product in
                        Button(product.description) {
                            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: siteID, productID: product.id, completion: { _ in }))
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
        stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
            switch result {
            case .success(let products):
                self.products = products
            case .failure(let error):
                print("Error loading products: \(error)")
            }
        }))
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView(siteID: 0)
    }
}
