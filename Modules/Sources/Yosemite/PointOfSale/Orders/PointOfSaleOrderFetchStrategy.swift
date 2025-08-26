import Foundation
import struct NetworkingCore.PagedItems

public protocol PointOfSaleOrderFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
}

struct PointOfSaleDefaultOrderFetchStrategy: PointOfSaleOrderFetchStrategy {
    private let orderService: PointOfSaleOrderServiceProtocol

    init(orderService: PointOfSaleOrderServiceProtocol) {
        self.orderService = orderService
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}
