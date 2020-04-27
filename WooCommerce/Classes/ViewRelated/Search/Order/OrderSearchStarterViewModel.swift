
import Foundation
import UIKit
import Yosemite

/// ViewModel for `OrderSearchStarterViewController`.
///
/// This encapsulates all the `OrderStatus` data loading and `UITableViewCell` presentation.
///
final class OrderSearchStarterViewModel {
    private lazy var dataSource = DataSource()

    /// Start all the operations that this `ViewModel` is responsible for.
    ///
    /// This should only be called once in the lifetime of `OrderSearchStarterViewController`.
    ///
    /// - Parameters:
    ///     - tableView: The table to use for the results. This is not retained by this class.
    ///
    func activate(using tableView: UITableView) {
        dataSource.startForwardingEvents(to: tableView)

        try? dataSource.performFetch()
    }

    /// The `OrderStatus` located at `indexPath`.
    ///
    func orderStatus(at indexPath: IndexPath) -> OrderStatus {
        dataSource.resultsController.object(at: indexPath)
    }
}

// MARK: - TableView Support

extension OrderSearchStarterViewModel {
    /// The number of DB results
    ///
    var numberOfObjects: Int {
        dataSource.resultsController.numberOfObjects
    }
}

private extension OrderSearchStarterViewModel {
    /// Encpsulates data loading and presentation of the `UITableViewCells`.
    ///
    final class DataSource: NSObject {
        private let storageManager = ServiceLocator.storageManager
        private let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min

        private(set) lazy var resultsController: ResultsController<StorageOrderStatus> = {
            let descriptor = NSSortDescriptor(key: "slug", ascending: true)
            let predicate = NSPredicate(format: "siteID == %lld", siteID)
            return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                         matching: predicate,
                                                         sortedBy: [descriptor])
        }()

        /// Run the query to fetch all the `OrderStatus`.
        ///
        func performFetch() throws {
            try resultsController.performFetch()
        }

        /// Attach events so the `tableView` is always kept up to date.
        ///
        /// This should only be called once.
        ///
        func startForwardingEvents(to tableView: UITableView) {
            resultsController.startForwardingEvents(to: tableView)
        }
    }
}
