// POSBookingService.swift
import Foundation
import Networking
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

/// Protocol for POS booking operations
public protocol POSBookingServiceProtocol: Sendable {
    /// Fetches today's bookings for the given site
    func fetchTodaysBookings(siteID: Int64) async throws -> [Booking]

    /// Marks a booking as paid
    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws
}

public final class POSBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    private let bookingsRemote: BookingsRemoteProtocol
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
                  stores: stores)
    }

    public init(bookingsRemote: BookingsRemoteProtocol,
                stores: StoresManager) {
        self.bookingsRemote = bookingsRemote
        self.stores = stores
    }

    // MARK: - Protocol conformance

    public func fetchTodaysBookings(siteID: Int64) async throws -> [Booking] {
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

        let bookings = try await bookingsRemote.loadAllBookings(
            for: siteID,
            pageNumber: 1,
            pageSize: 100,
            filters: filters,
            searchQuery: nil,
            order: .ascending
        )

        return bookings
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
