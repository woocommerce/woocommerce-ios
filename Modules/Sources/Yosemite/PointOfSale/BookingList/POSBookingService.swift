import Foundation
import enum Alamofire.AFError
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import protocol Networking.BookingsRemoteProtocol
import struct Networking.Booking
import struct Networking.BookingOrderInfo
import struct Networking.BookingResource
import protocol NetworkingCore.POSOrdersRemoteProtocol
import class WooFoundationCore.CurrencyFormatter

public final class POSBookingService: POSBookingServiceProtocol {
    private let siteID: Int64
    private let bookingsRemote: BookingsRemoteProtocol
    private let ordersRemote: POSOrdersRemoteProtocol
    private let mapper: POSBookingMapper

    public init(siteID: Int64,
                bookingsRemote: BookingsRemoteProtocol,
                ordersRemote: POSOrdersRemoteProtocol,
                currencyFormatter: CurrencyFormatter) {
        self.siteID = siteID
        self.bookingsRemote = bookingsRemote
        self.ordersRemote = ordersRemote
        self.mapper = POSBookingMapper(currencyFormatter: currencyFormatter)
    }

    public func fetchBookings(siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              searchQuery: String?) async throws -> PagedItems<POSBooking> {
        do {
            let bookings = try await bookingsRemote.loadAllBookings(
                for: siteID,
                pageNumber: pageNumber,
                pageSize: pageSize,
                filters: nil,
                searchQuery: searchQuery,
                order: .ascending
            )

            if pageNumber != 1 && bookings.isEmpty {
                return PagedItems(items: [], hasMorePages: false, totalItems: nil)
            }

            let orderIDs = Set(bookings.compactMap { $0.orderID != 0 ? $0.orderID : nil })
            let orders = await fetchOrders(orderIDs: Array(orderIDs))

            let resourceIDs = Set(bookings.compactMap { $0.resourceID != 0 ? $0.resourceID : nil })
            let resources = await fetchResources(resourceIDs: Array(resourceIDs))

            let posBookings = bookings.map { booking -> POSBooking in
                let order = orders[booking.orderID]
                let orderInfo: BookingOrderInfo? = order.map { BookingOrderInfo(booking: booking, order: $0) }
                let resource = resources[booking.resourceID]
                return mapper.map(booking: booking, orderInfo: orderInfo, resource: resource)
            }

            let hasMorePages = bookings.count == pageSize

            return PagedItems(items: posBookings, hasMorePages: hasMorePages, totalItems: nil)
        } catch AFError.explicitlyCancelled {
            throw POSBookingServiceError.requestCancelled
        } catch is POSBookingServiceError {
            throw POSBookingServiceError.requestCancelled
        } catch {
            throw POSBookingServiceError.requestFailed
        }
    }
}

private extension POSBookingService {
    func fetchOrders(orderIDs: [Int64]) async -> [Int64: Order] {
        guard !orderIDs.isEmpty else { return [:] }
        var result: [Int64: Order] = [:]
        await withTaskGroup(of: (Int64, Order?).self) { group in
            for orderID in orderIDs {
                group.addTask { [weak self] in
                    guard let self else { return (orderID, nil) }
                    let order = try? await self.ordersRemote.loadPOSOrder(siteID: self.siteID, orderID: orderID)
                    return (orderID, order)
                }
            }
            for await (orderID, order) in group {
                if let order {
                    result[orderID] = order
                }
            }
        }
        return result
    }

    func fetchResources(resourceIDs: [Int64]) async -> [Int64: BookingResource] {
        guard !resourceIDs.isEmpty else { return [:] }
        var result: [Int64: BookingResource] = [:]
        for resourceID in resourceIDs {
            if let resource = try? await bookingsRemote.fetchResource(resourceID: resourceID, siteID: siteID) {
                result[resourceID] = resource
            }
        }
        return result
    }
}
