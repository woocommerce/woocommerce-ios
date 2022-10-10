import SwiftUI
import StoreKit

struct UpgradesView: View {
    let siteID: Int64
    @State var hasPlan = false
    @State var products: [Product] = []
    private let inAppPurchaseService = ServiceLocator.inAppPurchaseService

    var body: some View {
        Group {
            if hasPlan {
                Text("Already upgraded")
            } else {
                List(products) { product in
                    Text(product.description)
                        .onTapGesture {
                            Task {
                                self.hasPlan = await inAppPurchaseService.purchaseWordPressPlan(for: siteID, product: product)
                            }
                        }
                }
            }
        }
        .task {
            do {
                products = try await inAppPurchaseService.fetchWordPressPlanProducts()
            } catch {
                print("Error loading products: \(error)")
            }
        }
    }
}

struct UpgradesView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradesView(siteID: 0)
    }
}
