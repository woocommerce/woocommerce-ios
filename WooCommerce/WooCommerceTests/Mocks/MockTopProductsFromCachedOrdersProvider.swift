@testable import WooCommerce
import Foundation

final class MockTopProductsFromCachedOrdersProvider: TopProductsFromCachedOrdersProviderProtocol {
    private let provideTopProductsFromCachedOrders: TopProductsFromCachedOrders

    init(provideTopProductsFromCachedOrders: TopProductsFromCachedOrders) {
        self.provideTopProductsFromCachedOrders = provideTopProductsFromCachedOrders
    }

    func provideTopProductsFromCachedOrders(siteID: Int64) -> TopProductsFromCachedOrders {
        provideTopProductsFromCachedOrders
    }
}
