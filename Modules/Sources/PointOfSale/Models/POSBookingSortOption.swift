import Foundation
import class Networking.BookingsRemote

enum POSBookingSortOption: CaseIterable, Equatable {
    case ascending
    case descending

    var order: BookingsRemote.Order {
        switch self {
        case .ascending:
            .ascending
        case .descending:
            .descending
        }
    }

    var title: String {
        switch self {
        case .ascending:
            Localization.upcomingToOldest
        case .descending:
            Localization.oldestToUpcoming
        }
    }
}

private enum Localization {
    static let upcomingToOldest = NSLocalizedString(
        "pos.bookingSortOption.upcomingToOldest",
        value: "Upcoming to oldest",
        comment: "Sort option for bookings list — shows soonest upcoming bookings first"
    )
    static let oldestToUpcoming = NSLocalizedString(
        "pos.bookingSortOption.oldestToUpcoming",
        value: "Oldest to upcoming",
        comment: "Sort option for bookings list — shows oldest bookings first"
    )
}
