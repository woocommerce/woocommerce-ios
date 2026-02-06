import Foundation
import Observation

@Observable final class POSBookingsModel {
    let bookingsController: POSSearchingBookingListControllerProtocol

    init(bookingsController: POSSearchingBookingListControllerProtocol) {
        self.bookingsController = bookingsController
    }
}
