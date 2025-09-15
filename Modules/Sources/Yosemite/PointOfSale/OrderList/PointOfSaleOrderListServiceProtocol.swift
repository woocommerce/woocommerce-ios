import Foundation
import struct NetworkingCore.PagedItems

public enum PointOfSaleOrderListServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol PointOfSaleOrderListServiceProtocol {
    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
    func searchPointOfSaleOrders(searchTerm: String, pageNumber: Int) async throws -> PagedItems<POSOrder>
    func loadOrder(orderID: Int64) async throws -> POSOrder
}
