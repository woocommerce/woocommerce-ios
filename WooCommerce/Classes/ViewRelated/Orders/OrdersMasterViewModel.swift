
import Foundation
import Yosemite

/// Encapsulates data management for `OrdersMasterViewController`.
///
final class OrdersMasterViewModel {

    private lazy var storageManager = ServiceLocator.storageManager

    /// ResultsController: Handles all things order status
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// The current list of order statuses for the default site
    ///
    var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }
}
