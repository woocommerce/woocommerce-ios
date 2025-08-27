import Foundation
import struct NetworkingCore.PagedItems

public enum PointOfSaleOrderListServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol PointOfSaleOrderListServiceProtocol {
    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
}
