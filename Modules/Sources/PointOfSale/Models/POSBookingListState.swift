// POSBookingListState.swift
import Foundation

enum POSBookingListState: Equatable {
    case loading
    case loaded([POSBooking])
    case empty
    case error(PointOfSaleErrorState)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var bookings: [POSBooking] {
        if case .loaded(let bookings) = self {
            return bookings
        }
        return []
    }
}
