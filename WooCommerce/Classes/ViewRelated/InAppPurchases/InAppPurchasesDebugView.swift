import SwiftUI
import StoreKit
import Yosemite

@MainActor
struct InAppPurchasesDebugView: View {
    private let inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
    @State var products: [WPComPlanProduct] = []
    @State var entitledProductIDs: Set<String> = []
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
                } else if let stringSiteID = ProcessInfo.processInfo.environment[Constants.siteIdEnvironmentVariableName],
                          let siteID = Int64(stringSiteID) {
                    ForEach(products, id: \.id) { product in
                        Button(entitledProductIDs.contains(product.id) ? "Entitled: \(product.description)" : product.description) {
                            Task {
                                isPurchasing = true
                                try? await inAppPurchasesForWPComPlansManager.purchaseProduct(with: product.id, for: siteID)
                                await loadUserEntitlements()
                                isPurchasing = false
                            }
                        }
                    }
                } else {
                    Text("No valid site id could be retrieved to purchase product. " +
                         "Please set your Int64 test site id to the Xcode environment variable with name \(Constants.siteIdEnvironmentVariableName).")
                        .foregroundColor(.red)
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await loadUserEntitlements()
            }
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
                    self.entitledProductIDs.insert(product.id)
                } else {
                    self.entitledProductIDs.remove(product.id)
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
        InAppPurchasesDebugView()
    }
}

private enum Constants {
    static let siteIdEnvironmentVariableName = "iap-debug-site-id-purchase-param"
}
