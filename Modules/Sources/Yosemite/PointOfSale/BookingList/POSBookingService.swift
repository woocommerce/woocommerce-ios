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
import Storage

public final class POSBookingService: POSBookingServiceProtocol {
    private let siteID: Int64
    private let bookingsRemote: BookingsRemoteProtocol
    private let ordersRemote: POSOrdersRemoteProtocol
    private let mapper: POSBookingMapper
    private let storageBookingMapper: StorageBookingToPOSBookingMapper
    private let orderMapper: POSOrderMapper
    private let resourceCache = BookingResourceCache()
    private let storageManager: StorageManagerType?

    public init(siteID: Int64,
                bookingsRemote: BookingsRemoteProtocol,
                ordersRemote: POSOrdersRemoteProtocol,
                currencyFormatter: CurrencyFormatter,
                storageManager: StorageManagerType? = nil,
                siteSettings: [SiteSetting] = []) {
        self.siteID = siteID
        self.bookingsRemote = bookingsRemote
        self.ordersRemote = ordersRemote
        self.mapper = POSBookingMapper(currencyFormatter: currencyFormatter, siteSettings: siteSettings)
        self.storageBookingMapper = StorageBookingToPOSBookingMapper(currencyFormatter: currencyFormatter, siteSettings: siteSettings)
        self.orderMapper = POSOrderMapper(currencyFormatter: currencyFormatter)
        self.storageManager = storageManager
    }

    public func fetchBookings(siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              filters: BookingFilters?,
                              searchQuery: String?) async throws -> PagedItems<POSBooking> {
        // Page 1 with date filters and no search: try local cache first
        if pageNumber == 1, searchQuery == nil, let filters, let storageManager {
            let cachedBookings = fetchCachedBookings(storageManager: storageManager, siteID: siteID, filters: filters)
            if cachedBookings.isNotEmpty {
                triggerBackgroundRefresh(siteID: siteID, pageSize: pageSize, filters: filters)
                return PagedItems(items: cachedBookings, hasMorePages: true, totalItems: nil)
            }
        }

        return try await fetchRemoteBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: searchQuery
        )
    }

}

// MARK: - Remote Fetching

private extension POSBookingService {
    func fetchRemoteBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             filters: BookingFilters?,
                             searchQuery: String?) async throws -> PagedItems<POSBooking> {
        do {
            let bookings = try await bookingsRemote.loadAllBookings(
                for: siteID,
                pageNumber: pageNumber,
                pageSize: pageSize,
                filters: filters,
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

            // Persist to CoreData for caching
            if let storageManager, searchQuery == nil {
                persistBookings(
                    storageManager: storageManager,
                    bookings: bookings,
                    orders: Array(orders.values),
                    siteID: siteID,
                    filters: pageNumber == 1 ? filters : nil
                )
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

    public func fetchBooking(bookingID: Int64) async throws -> POSBooking {
        guard let booking = try await bookingsRemote.loadBooking(bookingID: bookingID, siteID: siteID) else {
            throw POSBookingServiceError.requestFailed
        }

        let orderIDs = booking.orderID != 0 ? [booking.orderID] : []
        let resourceIDs = booking.resourceID != 0 ? [booking.resourceID] : []

        async let orderTask = fetchOrders(orderIDs: orderIDs)
        async let resourceTask = fetchResources(resourceIDs: resourceIDs)
        let (orders, resources) = await (orderTask, resourceTask)

        let order = orders[booking.orderID]
        let orderInfo: BookingOrderInfo? = order.map { BookingOrderInfo(booking: booking, order: $0) }
        let resource = resources[booking.resourceID]

        guard let posOrder = order.flatMap({ try? orderMapper.map(order: $0) }) else {
            throw POSBookingServiceError.requestFailed
        }

        return mapper.map(booking: booking, orderInfo: orderInfo, resource: resource, order: posOrder)
    }

    @discardableResult
    public func cancelBooking(bookingID: Int64) async throws -> BookingStatus {
        guard let booking = try await bookingsRemote.updateBooking(
            from: siteID,
            bookingID: bookingID,
            attendanceStatus: nil,
            bookingStatus: .cancelled,
            note: nil
        ) else {
            throw POSBookingServiceError.requestFailed
        }
        return booking.bookingStatus
    }

    @discardableResult
    public func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws -> BookingAttendanceStatus {
        guard let booking = try await bookingsRemote.updateBooking(
            from: siteID,
            bookingID: bookingID,
            attendanceStatus: status,
            bookingStatus: nil,
            note: nil
        ) else {
            throw POSBookingServiceError.requestFailed
        }
        return booking.attendanceStatus
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

// MARK: - Local Storage

private extension POSBookingService {
    func fetchCachedBookings(storageManager: StorageManagerType, siteID: Int64, filters: BookingFilters) -> [POSBooking] {
        let predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
        let descriptor = NSSortDescriptor(keyPath: \Storage.Booking.startDate, ascending: true)
        let resultsController = ResultsController<Storage.Booking>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor]
        )

        do {
            try resultsController.performFetch()
        } catch {
            return []
        }

        let readOnlyBookings = resultsController.fetchedObjects

        // Load resources from storage
        let resourceIDs = Set(readOnlyBookings.compactMap { $0.resourceID != 0 ? $0.resourceID : nil })
        let storedResources: [Int64: BookingResource] = {
            guard !resourceIDs.isEmpty else { return [:] }
            let resourcePredicate = NSPredicate(format: "siteID == %lld AND resourceID IN %@", siteID, Array(resourceIDs))
            let resourceDescriptor = NSSortDescriptor(keyPath: \Storage.BookingResource.resourceID, ascending: true)
            let resourceRC = ResultsController<Storage.BookingResource>(
                storageManager: storageManager,
                matching: resourcePredicate,
                sortedBy: [resourceDescriptor]
            )
            do {
                try resourceRC.performFetch()
            } catch {
                return [:]
            }
            return Dictionary(uniqueKeysWithValues: resourceRC.fetchedObjects.map { ($0.resourceID, $0) })
        }()

        return readOnlyBookings.compactMap { booking in
            let resource = storedResources[booking.resourceID]
            return storageBookingMapper.map(booking: booking, resource: resource)
        }
    }

    func triggerBackgroundRefresh(siteID: Int64, pageSize: Int, filters: BookingFilters?) {
        Task { [weak self] in
            _ = try? await self?.fetchRemoteBookings(
                siteID: siteID,
                pageNumber: 1,
                pageSize: pageSize,
                filters: filters,
                searchQuery: nil
            )
        }
    }

    func persistBookings(storageManager: StorageManagerType,
                         bookings: [Networking.Booking],
                         orders: [Order],
                         siteID: Int64,
                         filters: BookingFilters?) {
        storageManager.performAndSave({ storage in
            // Smart deletion: only delete bookings matching the filter scope on page 1
            if let filters {
                let predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
                storage.deleteBookings(matching: predicate)
            }

            // Upsert bookings
            let bookingIDs = bookings.map { $0.bookingID }
            let storedBookings = storage.loadBookings(siteID: siteID, bookingIDs: bookingIDs)

            for readOnlyBooking in bookings {
                let storageBooking = storedBookings.first { $0.bookingID == readOnlyBooking.bookingID } ??
                    storage.insertNewObject(ofType: Storage.Booking.self)

                if let associatedOrder = orders.first(where: { $0.orderID == readOnlyBooking.orderID }) {
                    let readOnlyOrderInfo = BookingOrderInfo(booking: readOnlyBooking, order: associatedOrder)

                    let orderInfo = storageBooking.orderInfo ?? storage.insertNewObject(ofType: Storage.BookingOrderInfo.self)

                    let productInfo = orderInfo.productInfo ?? storage.insertNewObject(ofType: Storage.BookingProductInfo.self)
                    if let readOnlyProductInfo = readOnlyOrderInfo.productInfo {
                        productInfo.update(with: readOnlyProductInfo)
                    }
                    orderInfo.productInfo = productInfo

                    let customerInfo = orderInfo.customerInfo ?? storage.insertNewObject(ofType: Storage.BookingCustomerInfo.self)
                    if let readOnlyCustomerInfo = readOnlyOrderInfo.customerInfo {
                        customerInfo.update(with: readOnlyCustomerInfo)
                    }
                    orderInfo.customerInfo = customerInfo

                    let paymentInfo = orderInfo.paymentInfo ?? storage.insertNewObject(ofType: Storage.BookingPaymentInfo.self)
                    if let readOnlyPaymentInfo = readOnlyOrderInfo.paymentInfo {
                        paymentInfo.update(with: readOnlyPaymentInfo)
                    }
                    orderInfo.paymentInfo = paymentInfo

                    orderInfo.update(with: readOnlyOrderInfo)
                    storageBooking.orderInfo = orderInfo
                }

                storageBooking.update(with: readOnlyBooking)
            }
        }, completion: nil, on: .main)
    }
}

// MARK: - BookingResourceCache

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
