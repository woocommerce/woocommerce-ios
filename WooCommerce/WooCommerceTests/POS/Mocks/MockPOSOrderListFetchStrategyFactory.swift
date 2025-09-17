import Foundation
@testable import WooCommerce
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderListFetchStrategy
import protocol Yosemite.POSOrderListServiceProtocol
import struct NetworkingCore.PagedItems
import struct Yosemite.POSOrder

final class MockPOSOrderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol {
    private let orderService: POSOrderListServiceProtocol

    init(orderService: POSOrderListServiceProtocol) {
        self.orderService = orderService
    }

    func defaultStrategy() -> POSOrderListFetchStrategy {
        MockPOSOrderListFetchStrategy(orderService: orderService)
    }

    func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy {
        MockPOSOrderListSearchFetchStrategy(orderService: orderService, searchTerm: searchTerm)
    }
}

private struct MockPOSOrderListFetchStrategy: POSOrderListFetchStrategy {
    let orderService: POSOrderListServiceProtocol

    var supportsCaching: Bool { true }
    var showsLoadingWithItems: Bool { true }
    var id: String = "default"

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> Yosemite.POSOrder {
        try await orderService.loadOrder(orderID: orderID)
    }
}

private struct MockPOSOrderListSearchFetchStrategy: POSOrderListFetchStrategy {
    let orderService: POSOrderListServiceProtocol
    let searchTerm: String

    var supportsCaching: Bool { false }
    var showsLoadingWithItems: Bool { false }
    var id: String = "search"

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.searchPointOfSaleOrders(searchTerm: searchTerm, pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> Yosemite.POSOrder {
        try await orderService.loadOrder(orderID: orderID)
    }
}
