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

    func searchStrategy(searchTerm: String) -> PointOfSaleOrderListFetchStrategy {
        MockPointOfSaleOrderListSearchFetchStrategy(orderService: orderService, searchTerm: searchTerm)
    }
}

private struct MockPointOfSaleOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    let orderService: PointOfSaleOrderListServiceProtocol

    var supportsCaching: Bool { true }
    var showsLoadingWithItems: Bool { true }
    var id: String = "default"

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}

private struct MockPointOfSaleOrderListSearchFetchStrategy: PointOfSaleOrderListFetchStrategy {
    let orderService: PointOfSaleOrderListServiceProtocol
    let searchTerm: String

    var supportsCaching: Bool { false }
    var showsLoadingWithItems: Bool { false }
    var id: String = "search"

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.searchPointOfSaleOrders(searchTerm: searchTerm, pageNumber: pageNumber)
    }
}
