// POSBookingService.swift
import Foundation
import Networking
import NetworkingCore
import struct Combine.AnyPublisher

/// Result of fetching enriched bookings with resources
public struct POSBookingFetchResult: Sendable {
    public let bookings: [Booking]
    public let resources: [Int64: BookingResource]

    public init(bookings: [Booking], resources: [Int64: BookingResource]) {
        self.bookings = bookings
        self.resources = resources
    }
}

/// Protocol for POS booking operations
public protocol POSBookingServiceProtocol: Sendable {
    /// Fetches today's bookings for the given site, enriched with order info and resources
    func fetchTodaysBookings(siteID: Int64) async throws -> POSBookingFetchResult

    /// Marks a booking as paid
    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws
}

public final class POSBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    private let bookingsRemote: BookingsRemoteProtocol
    private let ordersRemote: OrdersRemoteProtocol
    private let stores: StoresManager

    public convenience init?(siteID: Int64,
                             credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             stores: StoresManager) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSBookingService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(bookingsRemote: BookingsRemote(network: network),
                  ordersRemote: OrdersRemote(network: network),
                  stores: stores)
    }

    public init(bookingsRemote: BookingsRemoteProtocol,
                ordersRemote: OrdersRemoteProtocol,
                stores: StoresManager) {
        self.bookingsRemote = bookingsRemote
        self.ordersRemote = ordersRemote
        self.stores = stores
    }

    // MARK: - Protocol conformance

    public func fetchTodaysBookings(siteID: Int64) async throws -> POSBookingFetchResult {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw POSBookingServiceError.invalidDateRange
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let filters = BookingFilters(
            startDateBefore: dateFormatter.string(from: endOfDay),
            startDateAfter: dateFormatter.string(from: startOfDay)
        )

        DDLogInfo("📚 POSBookingService: Fetching bookings for siteID=\(siteID), after=\(dateFormatter.string(from: startOfDay)), before=\(dateFormatter.string(from: endOfDay))")

        let bookings: [Booking]
        do {
            bookings = try await bookingsRemote.loadAllBookings(
                for: siteID,
                pageNumber: 1,
                pageSize: 100,
                filters: filters,
                searchQuery: nil,
                order: .ascending
            )
            DDLogInfo("📚 POSBookingService: Fetched \(bookings.count) bookings successfully")
        } catch {
            DDLogError("⛔️ POSBookingService: loadAllBookings failed with error: \(error)")
            DDLogError("⛔️ POSBookingService: error localizedDescription: \(error.localizedDescription)")
            throw error
        }

        // Fetch orders for all bookings that have order IDs
        let orderIDs = bookings.compactMap { $0.orderID > 0 ? $0.orderID : nil }
        let orders = try await ordersRemote.loadOrders(for: siteID, orderIDs: orderIDs)

        // Enrich bookings with order info
        let enrichedBookings = bookings.map { booking -> Booking in
            guard let order = orders.first(where: { $0.orderID == booking.orderID }) else {
                return booking
            }
            let orderInfo = BookingOrderInfo(booking: booking, order: order)
            return booking.copy(orderInfo: orderInfo)
        }

        // Fetch resources for all bookings that have resource IDs
        let resourceIDs = Set(bookings.compactMap { $0.resourceID > 0 ? $0.resourceID : nil })
        DDLogInfo("📚 POSBookingService: Found \(resourceIDs.count) unique resource IDs from \(bookings.count) bookings")
        var resources: [Int64: BookingResource] = [:]

        for resourceID in resourceIDs {
            do {
                if let resource = try await bookingsRemote.fetchResource(resourceID: resourceID, siteID: siteID) {
                    resources[resourceID] = resource
                    DDLogInfo("📚 POSBookingService: Fetched resource \(resourceID): \(resource.name)")
                }
            } catch {
                DDLogError("⛔️ POSBookingService: Failed to fetch resource \(resourceID): \(error)")
            }
        }

        return POSBookingFetchResult(bookings: enrichedBookings, resources: resources)
    }

    public func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let action = BookingAction.markBookingAsPaid(
                siteID: siteID,
                bookingID: bookingID
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            Task { @MainActor in
                self.stores.dispatch(action)
            }
        }
    }
}

public extension POSBookingService {
    enum POSBookingServiceError: Error {
        case invalidDateRange
    }
}
