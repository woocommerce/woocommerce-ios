import SwiftUI
import StoreKit
import Yosemite

struct UpgradesView: View {
    let siteID: Int64
    @State var hasPlan = false
    @State var products: [StoreKit.Product] = []
    private let stores = ServiceLocator.stores

    var body: some View {
        Group {
            if hasPlan {
                Text("Already upgraded")
            } else {
                List(products) { product in
                    Text(product.description)
                        .onTapGesture {
                            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: siteID, product: product, completion: { result in
                                // TODO: handle pending case
                                switch result {
                                case .success(.success(_)):
                                    self.hasPlan = true
                                default:
                                    self.hasPlan = false
                                }
                            }))
                        }
                }
            }
        }
        .onAppear(perform: {
            stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
                switch result {
                case .success(let products):
                    self.products = products
                case .failure(let error):
                    print("Error loading products: \(error)")
                }
            }))
        })
    }
}

struct UpgradesView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradesView(siteID: 0)
    }
}
