import SwiftUI
import StoreKit

struct UpgradesView: View {
    @State var hasPlan = false
    @State var products: [Product] = []

    var body: some View {
        Group {
            if hasPlan {
                Text("Already upgraded")
            } else {
                List(products) { product in
                    Text(product.description)
                        .onTapGesture {
                            Task {
                                self.hasPlan = await Store.buyProduct(product)
                            }
                        }
                }
            }
        }
        .task {
            do {
                products = try await Store.getProducts()
            } catch {
                print("Error loading products: \(error)")
            }
        }
    }
}

private struct Store {
    private static let identifiers = [
        "com.woocommerce.test.hosted_1_yearly",
        "com.woocommerce.test.hosted_1_monthly"
    ]

    static func getProducts() async throws -> [Product] {
        return try await StoreKit.Product.products(for: identifiers)
    }

    static func buyProduct(_ product: Product) async -> Bool {
        let result = try? await product.purchase()
        switch result {
        case .success:
            return true
        default:
            return false
        }
    }
}

struct UpgradesView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradesView()
    }
}
