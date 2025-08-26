import Foundation
@testable import WooCommerce
import protocol Yosemite.PointOfSaleOrderFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSaleOrderFetchStrategy
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import struct NetworkingCore.PagedItems
import struct Yosemite.POSOrder

final class MockPointOfSaleOrderFetchStrategyFactory: PointOfSaleOrderFetchStrategyFactoryProtocol {
    private let orderService: PointOfSaleOrderServiceProtocol

    init(orderService: PointOfSaleOrderServiceProtocol) {
        self.orderService = orderService
    }

    func defaultStrategy() -> PointOfSaleOrderFetchStrategy {
        MockPointOfSaleOrderFetchStrategy(orderService: orderService)
    }
}

private struct MockPointOfSaleOrderFetchStrategy: PointOfSaleOrderFetchStrategy {
    let orderService: PointOfSaleOrderServiceProtocol

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}
