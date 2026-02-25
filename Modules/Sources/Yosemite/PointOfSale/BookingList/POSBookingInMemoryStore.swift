import Foundation

/// In-memory store for POS bookings, keyed by date range.
/// Replaces CoreData persistence for the POS booking list flow.
/// Shared across all `POSDefaultBookingListFetchStrategy` instances created by the same factory.
@MainActor
final class POSBookingInMemoryStore {

    struct DateRange: Hashable {
        let startDateAfter: String
        let startDateBefore: String
    }

    private var bookingsByDateRange: [DateRange: [POSBooking]] = [:]

    func bookings(for dateRange: DateRange, limit: Int?) -> [POSBooking] {
        let items = sorted(bookingsByDateRange[dateRange] ?? [])
        if let limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    /// Replaces all stored bookings for a date range. Used on page 1 fetches.
    func replaceBookings(_ bookings: [POSBooking], for dateRange: DateRange) {
        bookingsByDateRange[dateRange] = bookings
    }

    /// Appends bookings for a date range, deduplicating by ID. Used on page 2+ fetches.
    func appendBookings(_ bookings: [POSBooking], for dateRange: DateRange) {
        var existing = bookingsByDateRange[dateRange] ?? []
        let existingIDs = Set(existing.map(\.id))
        let uniqueNew = bookings.filter { !existingIDs.contains($0.id) }
        existing.append(contentsOf: uniqueNew)
        bookingsByDateRange[dateRange] = existing
    }

    func allBookings(for dateRange: DateRange) -> [POSBooking] {
        sorted(bookingsByDateRange[dateRange] ?? [])
    }
}

private extension POSBookingInMemoryStore {
    /// Matches the previous CoreData sort: startDate ascending, then id ascending.
    func sorted(_ bookings: [POSBooking]) -> [POSBooking] {
        bookings.sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }
            return lhs.id < rhs.id
        }
    }
}
