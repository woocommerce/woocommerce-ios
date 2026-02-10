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
    private let orderMapper: POSOrderMapper
    private let resourceCache = BookingResourceCache()

    public init(siteID: Int64,
                bookingsRemote: BookingsRemoteProtocol,
                ordersRemote: POSOrdersRemoteProtocol,
                currencyFormatter: CurrencyFormatter,
                siteSettings: [SiteSetting] = []) {
        self.siteID = siteID
        self.bookingsRemote = bookingsRemote
        self.ordersRemote = ordersRemote
        self.mapper = POSBookingMapper(currencyFormatter: currencyFormatter, siteSettings: siteSettings)
        self.orderMapper = POSOrderMapper(currencyFormatter: currencyFormatter)
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

            if pageNumber == 1 {
                await resourceCache.clear()
            }

            if pageNumber != 1 && bookings.isEmpty {
                return PagedItems(items: [], hasMorePages: false, totalItems: nil)
            }

            let orderIDs = Set(bookings.compactMap { $0.orderID != 0 ? $0.orderID : nil })
            let resourceIDs = Set(bookings.compactMap { $0.resourceID != 0 ? $0.resourceID : nil })

            async let ordersTask = fetchOrders(orderIDs: Array(orderIDs))
            async let resourcesTask = fetchResources(resourceIDs: Array(resourceIDs))
            let (orders, resources) = await (ordersTask, resourcesTask)

            let posBookings = bookings.compactMap { booking -> POSBooking? in
                let order = orders[booking.orderID]
                let orderInfo: BookingOrderInfo? = order.map { BookingOrderInfo(booking: booking, order: $0) }
                let resource = resources[booking.resourceID]
                guard let posOrder = order.flatMap({ try? orderMapper.map(order: $0) }) else {
                    return nil
                }
                return mapper.map(booking: booking, orderInfo: orderInfo, resource: resource, order: posOrder)
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
        var uncachedIDs: [Int64] = []
        for id in resourceIDs {
            if let cached = await resourceCache.resource(for: id) {
                result[id] = cached
            } else {
                uncachedIDs.append(id)
            }
        }
        guard !uncachedIDs.isEmpty else { return result }
        await withTaskGroup(of: (Int64, BookingResource?).self) { group in
            for resourceID in uncachedIDs {
                group.addTask { [weak self] in
                    guard let self else { return (resourceID, nil) }
                    let resource = try? await self.bookingsRemote.fetchResource(resourceID: resourceID, siteID: self.siteID)
                    return (resourceID, resource)
                }
            }
            for await (resourceID, resource) in group {
                if let resource {
                    result[resourceID] = resource
                }
            }
        }
        await resourceCache.store(result)
        return result
    }
}

// MARK: - BookingResourceCache
// Caches booking resources across pages to avoid redundant network requests,
// since multiple bookings often share the same resource. Cleared on page 1 reload.

private actor BookingResourceCache {
    private var cache: [Int64: BookingResource] = [:]

    func resource(for id: Int64) -> BookingResource? {
        cache[id]
    }

    func store(_ resources: [Int64: BookingResource]) {
        for (id, resource) in resources {
            cache[id] = resource
        }
    }

    func clear() {
        cache.removeAll()
    }
}
