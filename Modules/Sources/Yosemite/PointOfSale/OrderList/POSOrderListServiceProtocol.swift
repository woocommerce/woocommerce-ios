import Foundation
import struct NetworkingCore.PagedItems

public enum POSOrderListServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol POSOrderListServiceProtocol {
    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
    func searchPointOfSaleOrders(searchTerm: String, pageNumber: Int) async throws -> PagedItems<POSOrder>
    func loadOrder(orderID: Int64) async throws -> POSOrder
}
