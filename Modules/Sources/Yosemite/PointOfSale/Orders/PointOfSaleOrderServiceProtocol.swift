import Foundation
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order

public enum PointOfSaleOrderServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
    case unknown
}

public protocol PointOfSaleOrderServiceProtocol {
    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<Order>
}
