import Foundation
import Networking
import Storage

/// BookingStoreMethods extracts persistence functionality from BookingStore for reuse within Yosemite.
/// Intentionally internal - not exposed outside the module.
///
internal protocol BookingStoreMethodsProtocol {
    /// Syncs bookings from remote and persists to local storage.
    /// On page 1 with filters, performs smart deletion (only deletes bookings matching the filter scope).
    /// On page 1 without filters, deletes all bookings for the site.
    /// On subsequent pages, appends (upsert only, no deletion).
    ///
    /// - Returns: `true` if there are more pages to fetch.
    func synchronizeBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             filters: BookingFilters?,
                             searchQuery: String?) async throws -> Bool
}

internal class BookingStoreMethods: BookingStoreMethodsProtocol {
    private let bookingsRemote: BookingsRemoteProtocol
    private let ordersRemote: OrdersRemoteProtocol
    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType,
         bookingsRemote: BookingsRemoteProtocol,
         ordersRemote: OrdersRemoteProtocol) {
        self.storageManager = storageManager
        self.bookingsRemote = bookingsRemote
        self.ordersRemote = ordersRemote
    }

    func synchronizeBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             filters: BookingFilters?,
                             searchQuery: String?) async throws -> Bool {
        let bookings = try await bookingsRemote.loadAllBookings(
            for: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: searchQuery,
            order: .ascending
        )

        let orders = try await ordersRemote.loadOrders(
            for: siteID,
            orderIDs: bookings.map { $0.orderID }
        )

        let isFirstPage = pageNumber == 1
        await upsertStoredBookingsInBackground(
            readOnlyBookings: bookings,
            readOnlyOrders: orders,
            siteID: siteID,
            shouldDeleteAllBookings: isFirstPage && filters == nil,
            deleteFilters: isFirstPage ? filters : nil
        )

        return bookings.count == pageSize
    }
}

// MARK: - Persistence

private extension BookingStoreMethods {
    func upsertStoredBookingsInBackground(readOnlyBookings: [Networking.Booking],
                                          readOnlyOrders: [Networking.Order],
                                          siteID: Int64,
                                          shouldDeleteAllBookings: Bool = false,
                                          deleteFilters: BookingFilters? = nil) async {
        await withCheckedContinuation { continuation in
            storageManager.performAndSave({ storage in
                if shouldDeleteAllBookings {
                    storage.deleteBookings(siteID: siteID)
                } else if let deleteFilters {
                    let predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: deleteFilters)
                    storage.deleteBookings(matching: predicate)
                }
                Self.upsertStoredBookings(readOnlyBookings: readOnlyBookings, readOnlyOrders: readOnlyOrders, in: storage)
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }

    static func upsertStoredBookings(readOnlyBookings: [Networking.Booking],
                                     readOnlyOrders: [Networking.Order],
                                     in storage: StorageType) {
        let bookingIDs = readOnlyBookings.map { $0.bookingID }
        let siteID = readOnlyBookings.first?.siteID ?? 0
        let storedBookings = storage.loadBookings(siteID: siteID, bookingIDs: bookingIDs)

        for readOnlyBooking in readOnlyBookings {
            let storageBooking = storedBookings.first { $0.bookingID == readOnlyBooking.bookingID } ??
                storage.insertNewObject(ofType: Storage.Booking.self)

            if let associatedOrder = readOnlyOrders.first(where: { $0.orderID == readOnlyBooking.orderID }) {
                let readOnlyOrderInfo = Networking.BookingOrderInfo(booking: readOnlyBooking, order: associatedOrder)

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
    }
}
