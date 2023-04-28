@testable import WooCommerce
import Foundation

final class MockProductSelectorTopProductsProvider: ProductSelectorTopProductsProviderProtocol {
    private let provideTopProducts: ProductSelectorTopProducts

    init(provideTopProductsFromCachedOrders: ProductSelectorTopProducts) {
        self.provideTopProducts = provideTopProductsFromCachedOrders
    }

    func provideTopProducts(siteID: Int64) -> ProductSelectorTopProducts {
        provideTopProducts
    }
}
