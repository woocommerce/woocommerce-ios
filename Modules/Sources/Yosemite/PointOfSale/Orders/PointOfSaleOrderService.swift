import Foundation
import enum Alamofire.AFError
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import protocol NetworkingCore.POSOrdersRemoteProtocol

public final class PointOfSaleOrderService: PointOfSaleOrderServiceProtocol {
    private let ordersRemote: POSOrdersRemoteProtocol
    private let siteID: Int64

    public init(siteID: Int64, ordersRemote: POSOrdersRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
    }

    public func providePointOfSaleOrders(pageNumber: Int = 1) async throws -> PagedItems<Order> {
        do {
            let pagedOrders = try await ordersRemote.loadPOSOrders(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: 25
            )

            if pageNumber != 1 && pagedOrders.items.count == 0 {
                return .init(items: [], hasMorePages: false, totalItems: 0)
            }

            return pagedOrders
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleOrderServiceError.requestCancelled
        } catch {
            throw PointOfSaleOrderServiceError.requestFailed
        }
    }
}
