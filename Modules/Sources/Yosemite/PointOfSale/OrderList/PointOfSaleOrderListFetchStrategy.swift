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
