import Foundation
import Networking
import Storage

/// BookingStoreMethods extracts persistence functionality from BookingStore for reuse within Yosemite.
/// Intentionally internal - not exposed outside the module.
///
internal protocol BookingStoreMethodsProtocol {
    /// Syncs bookings from remote and persists to local storage.
    ///
    /// - Returns: `true` if there are more pages to fetch.
    func synchronizeBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             filters: BookingFilters?,
                             searchQuery: String?,
                             order: BookingsRemote.Order,
                             cacheClearStrategy: BookingStoreMethods.CacheClearStrategy) async throws -> Bool
}

internal final class BookingStoreMethods: BookingStoreMethodsProtocol {

    enum CacheClearStrategy {
        case none
        case all
        case filtersOnly(BookingFilters)
    }

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
                             searchQuery: String?,
                             order: BookingsRemote.Order = .ascending,
                             cacheClearStrategy: CacheClearStrategy = .none) async throws -> Bool {
        let bookings = try await bookingsRemote.loadAllBookings(
            for: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: searchQuery,
            order: order
        )

        let orders = try await ordersRemote.loadOrders(
            for: siteID,
            orderIDs: bookings.map { $0.orderID }
        )

        await upsertStoredBookingsInBackground(
            readOnlyBookings: bookings,
            readOnlyOrders: orders,
            siteID: siteID,
            cacheClearStrategy: cacheClearStrategy
        )

        return bookings.count == pageSize
    }
}

// MARK: - Persistence

private extension BookingStoreMethods {
    func upsertStoredBookingsInBackground(readOnlyBookings: [Networking.Booking],
                                          readOnlyOrders: [Networking.Order],
                                          siteID: Int64,
                                          cacheClearStrategy: CacheClearStrategy = .none) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume()
            }
            storageManager.performAndSave({ [weak self] storage in
                guard let self else { return }
                switch cacheClearStrategy {
                case .none:
                    break
                case .all:
                    storage.deleteBookings(siteID: siteID)
                case .filtersOnly(let filters):
                    let predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
                    storage.deleteBookings(matching: predicate)
                }
                self.upsertStoredBookings(readOnlyBookings: readOnlyBookings, readOnlyOrders: readOnlyOrders, in: storage)
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }

}

// MARK: - Upsert

extension BookingStoreMethods {
    func upsertStoredBookings(readOnlyBookings: [Networking.Booking],
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

                // Persist line items (replace all on each sync)
                let existingLineItems = orderInfo.lineItems?.array as? [Storage.BookingOrderLineItem] ?? []
                existingLineItems.forEach { storage.deleteObject($0) }
                for readOnlyLineItem in readOnlyOrderInfo.lineItems {
                    let storageLineItem = storage.insertNewObject(ofType: Storage.BookingOrderLineItem.self)
                    storageLineItem.update(with: readOnlyLineItem)
                    storageLineItem.orderInfo = orderInfo
                }

                // Persist refunds (replace all on each sync)
                let existingRefunds = orderInfo.refunds as? Set<Storage.BookingOrderRefund> ?? []
                existingRefunds.forEach { storage.deleteObject($0) }
                for readOnlyRefund in readOnlyOrderInfo.refunds {
                    let storageRefund = storage.insertNewObject(ofType: Storage.BookingOrderRefund.self)
                    storageRefund.update(with: readOnlyRefund)
                    storageRefund.orderInfo = orderInfo
                }

                orderInfo.update(with: readOnlyOrderInfo)
                storageBooking.orderInfo = orderInfo
            }

            storageBooking.update(with: readOnlyBooking)
        }
    }
}
