import Foundation
@testable import WooCommerce
import protocol Yosemite.PointOfSaleOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSaleOrderListFetchStrategy
import protocol Yosemite.PointOfSaleOrderListServiceProtocol
import struct NetworkingCore.PagedItems
import struct Yosemite.POSOrder

final class MockPointOfSaleOrderListFetchStrategyFactory: PointOfSaleOrderListFetchStrategyFactoryProtocol {
    private let orderService: PointOfSaleOrderListServiceProtocol

    init(orderService: PointOfSaleOrderListServiceProtocol) {
        self.orderService = orderService
    }

    func defaultStrategy() -> PointOfSaleOrderListFetchStrategy {
        MockPointOfSaleOrderListFetchStrategy(orderService: orderService)
    }
}

private struct MockPointOfSaleOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    let orderService: PointOfSaleOrderListServiceProtocol

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}
