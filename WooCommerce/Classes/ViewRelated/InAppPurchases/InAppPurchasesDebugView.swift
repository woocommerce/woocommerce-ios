import SwiftUI
import StoreKit
import Yosemite

struct InAppPurchasesDebugView: View {
    private let stores = ServiceLocator.stores
    @State var products: [StoreKit.Product] = []
    @State var transactions: [UInt64: StoreKit.Transaction] = [:]

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
                            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: 0, product: product, completion: { _ in }))
                        }
                    }
                }
            }
            Section("Transactions") {
                if transactions.isEmpty {
                    Text("No transactions")
                } else {
                    ForEach(Array(transactions.values)) { transaction in
                        InAppPurchasesDebugTransaction(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle("IAP Debug")
        .onAppear {
            loadProducts()
        }
        .task {
            await readCurrentTransactions()
            await listenForTransactions()
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

    private func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            guard case .verified(let transaction) = result else {
                continue
            }
            DDLogDebug("💰 IAP Transaction Update \(transaction.id): \(transaction)")
            self.transactions[transaction.id] = transaction
        }
    }

    private func readCurrentTransactions() async {
        for await result in StoreKit.Transaction.all {
            guard case .verified(let transaction) = result else {
                continue
            }
            DDLogDebug("💰 IAP Initial Transaction \(transaction.id): \(transaction)")
            self.transactions[transaction.id] = transaction
        }
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView()
    }
}
