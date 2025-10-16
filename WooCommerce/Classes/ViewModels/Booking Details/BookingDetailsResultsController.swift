import Foundation
import Yosemite
import Storage

final class BookingDetailsResultsController {
    private let storageManager: StorageManagerType
    private let bookingResultsController: ResultsController<StorageBooking>

    var booking: Yosemite.Booking? {
        bookingResultsController.fetchedObjects.first
    }

    init(booking: Yosemite.Booking, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager

        bookingResultsController = ResultsController<StorageBooking>(
            storageManager: storageManager,
            matching: NSPredicate(
                format: "siteID = %ld AND bookingID = %ld",
                booking.siteID,
                booking.bookingID
            ),
            sortedBy: []
        )
    }

    func configure(onReload: @escaping () -> Void) {
        bookingResultsController.onDidChangeContent = {
            onReload()
        }

        bookingResultsController.onDidResetContent = { [weak self] in
            try? self?.bookingResultsController.performFetch()
            onReload()
        }

        do {
            try bookingResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Booking: \(error)")
        }
    }
}
