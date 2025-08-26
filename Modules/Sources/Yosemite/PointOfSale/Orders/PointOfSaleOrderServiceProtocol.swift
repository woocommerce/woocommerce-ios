import Foundation
import struct NetworkingCore.PagedItems

public enum PointOfSaleOrderServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol PointOfSaleOrderServiceProtocol {
    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
}
