import Foundation
import struct NetworkingCore.PagedItems

public protocol PointOfSaleOrderFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
}

public struct PointOfSaleDefaultOrderFetchStrategy: PointOfSaleOrderFetchStrategy {
    private let orderService: PointOfSaleOrderServiceProtocol

    public init(orderService: PointOfSaleOrderServiceProtocol) {
        self.orderService = orderService
    }

    public func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderService.providePointOfSaleOrders(pageNumber: pageNumber)
    }
}
