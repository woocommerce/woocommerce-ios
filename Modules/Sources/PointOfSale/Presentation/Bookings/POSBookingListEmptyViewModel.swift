import Foundation
import SwiftUI

struct POSBookingListEmptyViewModel: POSListEmptyViewModelProtocol {
    let isSearching: Bool

    var title: String {
        isSearching ? Localization.emptyBookingsSearchTitle : Localization.emptyBookingsTitle
    }

    var subtitle: String {
        isSearching ? Localization.emptyBookingsSearchSubtitle : Localization.emptyBookingsSubtitle
    }

    var buttonTitle: String? {
        nil
    }

    var icon: Image {
        isSearching ? PointOfSaleAssets.magnifierNotFound.decorativeImage : PointOfSaleAssets.noOrders.decorativeImage
    }
}

private enum Localization {
    static let emptyBookingsTitle = NSLocalizedString(
        "pos.bookingListView.emptyBookingsTitle.2",
        value: "No bookings for this day",
        comment: "Title appearing when there are no bookings to display."
    )

    static let emptyBookingsSubtitle = NSLocalizedString(
        "pos.bookingListView.emptyBookingsSubtitle.2",
        value: "Any bookings scheduled for this date will appear here.",
        comment: "Subtitle appearing when there are no bookings to display."
    )

    static let emptyBookingsSearchTitle = NSLocalizedString(
        "pos.bookingListView.emptyBookingsSearchTitle",
        value: "No bookings found",
        comment: "Title appearing when booking search returns no results."
    )

    static let emptyBookingsSearchSubtitle = NSLocalizedString(
        "pos.bookingListView.emptyBookingsSearchSubtitle",
        value: "We couldn't find any bookings matching your search. Try adjusting your search term.",
        comment: "Subtitle appearing when booking search returns no results."
    )
}
