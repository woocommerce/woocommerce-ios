
import Foundation
import UIKit
import Yosemite

import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

/// ViewModel for `OrderSearchStarterViewController`.
///
/// This encapsulates all the `OrderStatus` data loading and `UITableViewCell` presentation.
///
final class OrderSearchStarterViewModel {
    private let siteID: Int64
    private let storageManager: StorageManagerType

    private lazy var resultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager,
                                                     matching: predicate,
                                                     sortedBy: [descriptor])
    }()

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager
    }

    /// Start all the operations that this `ViewModel` is responsible for.
    ///
    /// This should only be called once in the lifetime of `OrderSearchStarterViewController`.
    ///
    /// - Parameters:
    ///     - tableView: The table to use for the results. This is not retained by this class.
    ///
    func activateAndForwardUpdates(to tableView: UITableView) {
        resultsController.startForwardingEvents(to: tableView)

        performFetch()
    }

    /// Fetch and log the error if there's any.
    ///
    private func performFetch() {
        do {
            try resultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }
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
