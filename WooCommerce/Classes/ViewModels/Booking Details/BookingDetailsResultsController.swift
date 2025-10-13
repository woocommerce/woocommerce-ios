import Foundation
import Yosemite
import Storage

final class BookingDetailsResultsController {
    private let storageManager: StorageManagerType
    private let booking: Yosemite.Booking

    private lazy var orderResultsController: ResultsController<StorageOrder> = {
        let predicate = NSPredicate(
            format: "siteID = %ld AND orderID = %ld",
            booking.siteID,
            booking.orderID
        )
        return ResultsController<StorageOrder>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: []
        )
    }()

    var order: Yosemite.Order? {
        orderResultsController.fetchedObjects.first
    }

    init(booking: Yosemite.Booking, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.booking = booking
        self.storageManager = storageManager
    }

    func configure(onReload: @escaping () -> Void) {
        orderResultsController.onDidChangeContent = {
            onReload()
        }

        orderResultsController.onDidResetContent = { [weak self] in
            try? self?.orderResultsController.performFetch()
            onReload()
        }

        do {
            try orderResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Order for Booking: \(error)")
        }
    }
}
