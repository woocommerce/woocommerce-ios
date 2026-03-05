import Foundation
import struct Yosemite.POSBooking

enum POSBookingListState: Equatable {
    case loading([POSBooking], context: LoadingContext = .firstPage)
    case loaded([POSBooking], hasMoreItems: Bool)
    case inlineError([POSBooking], error: PointOfSaleErrorState, context: InlineErrorContext)
    case error(PointOfSaleErrorState)
    case empty

    enum LoadingContext {
        case firstPage
        case nextPage
    }

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var isPaginating: Bool {
        if case .loading(_, .nextPage) = self {
            return true
        }
        return false
    }

    var isEmpty: Bool {
        switch self {
        case .loaded:
            return false
        case .loading(let bookings, _):
            return bookings.isEmpty
        default:
            return true
        }
    }

    var bookings: [POSBooking] {
        switch self {
        case .loading(let bookings, _),
             .loaded(let bookings, _),
             .inlineError(let bookings, _, _):
            return bookings
        case .error, .empty:
            return []
        }
    }

    func updatingBookings(with updatedBookings: [POSBooking]) -> POSBookingListState {
        switch self {
        case .loaded(_, let hasMoreItems):
            return .loaded(updatedBookings, hasMoreItems: hasMoreItems)
        case .loading(_, let context):
            return .loading(updatedBookings, context: context)
        case .inlineError(_, let error, let context):
            return .inlineError(updatedBookings, error: error, context: context)
        case .empty, .error:
            return self
        }
    }
}
