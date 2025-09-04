import Foundation
import struct NetworkingCore.PagedItems

public protocol PointOfSaleOrderListFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
}

struct PointOfSaleDefaultOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    private let orderListService: PointOfSaleOrderListServiceProtocol

    init(orderListService: PointOfSaleOrderListServiceProtocol) {
        self.orderListService = orderListService
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}

struct PointOfSaleSearchOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    private let orderListService: PointOfSaleOrderListServiceProtocol
    private let searchTerm: String

    init(orderListService: PointOfSaleOrderListServiceProtocol, searchTerm: String) {
        self.orderListService = orderListService
        self.searchTerm = searchTerm
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.searchPointOfSaleOrders(searchTerm: searchTerm, pageNumber: pageNumber)
    }
}
