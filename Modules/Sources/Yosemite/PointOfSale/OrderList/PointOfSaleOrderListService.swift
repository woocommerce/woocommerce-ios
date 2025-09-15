import Foundation
import enum Alamofire.AFError
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import protocol NetworkingCore.POSOrdersRemoteProtocol
import class WooFoundationCore.CurrencyFormatter

public final class PointOfSaleOrderListService: PointOfSaleOrderListServiceProtocol {
    private let ordersRemote: POSOrdersRemoteProtocol
    private let siteID: Int64
    private let mapper: POSOrderMapper

    public init(
        siteID: Int64,
        ordersRemote: POSOrdersRemoteProtocol,
        currencyFormatter: CurrencyFormatter
    ) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
        self.mapper = POSOrderMapper(currencyFormatter: currencyFormatter)
    }

    public func providePointOfSaleOrders(pageNumber: Int = 1) async throws -> PagedItems<POSOrder> {
        do {
            let pagedOrders = try await ordersRemote.loadPOSOrders(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: 25
            )

            if pageNumber != 1 && pagedOrders.items.count == 0 {
                return .init(items: [], hasMorePages: false, totalItems: 0)
            }

            // Convert Order objects to POSOrder objects
            let posOrders = pagedOrders.items.map { mapper.map(order: $0) }

            return .init(items: posOrders,
                        hasMorePages: pagedOrders.hasMorePages,
                        totalItems: pagedOrders.totalItems)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleOrderListServiceError.requestCancelled
        } catch {
            throw PointOfSaleOrderListServiceError.requestFailed
        }
    }

    public func searchPointOfSaleOrders(searchTerm: String, pageNumber: Int = 1) async throws -> PagedItems<POSOrder> {
        do {
            let pagedOrders = try await ordersRemote.searchPOSOrders(
                siteID: siteID,
                searchTerm: searchTerm,
                pageNumber: pageNumber,
                pageSize: 25
            )

            if pageNumber != 1 && pagedOrders.items.count == 0 {
                return .init(items: [], hasMorePages: false, totalItems: 0)
            }

            // Convert Order objects to POSOrder objects
            let posOrders = pagedOrders.items.map { mapper.map(order: $0) }

            return .init(items: posOrders,
                        hasMorePages: pagedOrders.hasMorePages,
                        totalItems: pagedOrders.totalItems)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleOrderListServiceError.requestCancelled
        } catch {
            throw PointOfSaleOrderListServiceError.requestFailed
        }
    }

    public func loadOrder(orderID: Int64) async throws -> POSOrder {
        do {
            let order = try await ordersRemote.loadPOSOrder(siteID: siteID, orderID: orderID)
            return mapper.map(order: order)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleOrderListServiceError.requestCancelled
        } catch {
            throw PointOfSaleOrderListServiceError.requestFailed
        }
    }
}
