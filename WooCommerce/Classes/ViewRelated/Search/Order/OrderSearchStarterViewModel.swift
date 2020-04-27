
import Foundation
import UIKit
import Yosemite

/// ViewModel for `OrderSearchStarterViewController`.
///
/// This encapsulates all the `OrderStatus` data loading and `UITableViewCell` presentation.
///
final class OrderSearchStarterViewModel {
    private let storageManager = ServiceLocator.storageManager
    private let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min

    private lazy var resultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                     matching: predicate,
                                                     sortedBy: [descriptor])
    }()

    /// Start all the operations that this `ViewModel` is responsible for.
    ///
    /// This should only be called once in the lifetime of `OrderSearchStarterViewController`.
    ///
    /// - Parameters:
    ///     - tableView: The table to use for the results. This is not retained by this class.
    ///
    func activate(using tableView: UITableView) {
        resultsController.startForwardingEvents(to: tableView)

        try? resultsController.performFetch()
    }
}

// MARK: - TableView Support

extension OrderSearchStarterViewModel {
    /// The number of DB results
    ///
    var numberOfObjects: Int {
        resultsController.numberOfObjects
    }

    /// The `OrderStatus` located at `indexPath`.
    ///
    func orderStatus(at indexPath: IndexPath) -> OrderStatus {
        resultsController.object(at: indexPath)
    }
}
