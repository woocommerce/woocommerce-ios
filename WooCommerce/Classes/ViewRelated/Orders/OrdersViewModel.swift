
import Foundation
import Yosemite

/// ViewModel for `OrdersViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
/// Important: The `OrdersViewController` **owned** by `OrdersMasterViewController` currently
/// does not get deallocated when switching sites. This `ViewModel` should consider that and not
/// keep site-specific information as much as possible. For example, we shouldn't keep `siteID`
/// in here but grab it from the `SessionManager` when we need it. Hopefully, we will be able to
/// fix this in the future.
///
final class OrdersViewModel {
    enum SyncReason: String {
        case pullToRefresh = "pull_to_refresh"
    }

    func synchronizationAction(siteID: Int64,
                               statusKey: String?,
                               pageNumber: Int,
                               pageSize: Int,
                               reason: SyncReason?,
                               completionHandler: @escaping (Error?) -> Void) -> OrderAction {
        if pageNumber == Defaults.pageFirstIndex {
            let deleteAllBeforeSaving = reason == SyncReason.pullToRefresh

            return OrderAction.fetchFilteredAndAllOrders(
                siteID: siteID,
                statusKey: statusKey,
                deleteAllBeforeSaving: deleteAllBeforeSaving,
                pageSize: pageSize,
                onCompletion: completionHandler
            )
        }

        return OrderAction.synchronizeOrders(
            siteID: siteID,
            statusKey: statusKey,
            pageNumber: pageNumber,
            pageSize: pageSize,
            onCompletion: completionHandler
        )
    }
}

extension OrdersViewModel {
    enum Defaults {
        static let pageFirstIndex = SyncingCoordinator.Defaults.pageFirstIndex
    }
}
