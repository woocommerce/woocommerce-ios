import Foundation

import enum Yosemite.OrderAction
import struct Yosemite.OrderStatus

/// Returns what `OrderAction` should be used when synchronizing a list of orders.
///
/// This is meant to be used by `OrderListViewModel` (and the deprecated `OrdersViewModel`).
///
/// ## Discussion
///
/// Pulling to refresh on filtered lists, like the Processing tab, will perform 2 network GET
/// requests:
///
/// 1. Fetch the /orders?status=processed
/// 2. Fetch the /orders?status=any
///
/// We will also delete all the orders before saving the new fetched ones.
///
/// We are currently doing this to avoid showing stale orders to users (https://git.io/JvMME).
/// An example scenario is:
///
/// 1. Load the Processing tab.
/// 2. In the web, change one of the _processing_ orders to a different status (e.g. completed).
/// 3. Pull to refresh on the Processing tab.
///
/// If we were only doing one query, we would be fetching `GET /orders?status=processed` only.
/// But that doesn't include the old order which was changed to a different status and is no
/// longer in the response list. Hence, that updated order will stay on the tab and is stale.
///
///
/// ## Why a Dual Fetch
///
/// We could just delete all the orders and perform a single fetch of
/// `GET /orders?status=processed`. But this could result into the user viewing an incomplete
/// All Orders tab until we queried again. It's a jarring experience. Consider this scenario:
///
/// 1. Navigate to Processing and All Orders tab to load their content.
/// 2. Pull to refresh on the Processing tab.
/// 3. Navigate back to the All Orders tab.
///
/// On Step 3, since we deleted all the orders and only downloaded new processing orders, the
/// All Orders tab will initially contain just those orders.
///
/// The dual fetch is a "hack" to hide the sceanrio.
///
///
/// ## Deleting all the Orders
///
/// This sync strategy doesn't fix all our problems. I'm sure there are other scenarios that
/// can cause stale data. In fact, synchronization by `pageNumber` almost always has bugs
/// because orders could be on a different (previous) page when you load the next page. That
/// order would then end up not getting loaded at all.
///
/// Deleting all the orders during a pull to refresh is a "confidence button" for our users.
/// When they use this, we are guaranteeing them that they will be viewing an up to date list.
///
///
/// ## Spec
///
/// This is how sync behaves on different scenarios.
///
/// | Action           | Current Tab | Delete All | GET ?status=processing | GET ?status=any |
/// |------------------|-------------|------------|------------------------|-----------------|
/// | Pull-to-refresh  | Processing  | y          | y                      | y               |
/// | App activated    | Processing  | .          | y                      | y               |
/// | `viewWillAppear` | Processing  | .          | y                      | y               |
/// | Load next page   | Processing  | .          | y                      | .               |
/// | Pull-to-refresh  | All Orders  | y          | .                      | y               |
/// | App activated    | All Orders  | .          | .                      | y               |
/// | `viewWillAppear` | All Orders  | .          | .                      | y               |
/// | Load next page   | All Orders  | .          | .                      | y               |
///
struct OrderListSyncActionUseCase {

    /// The reasons passed to `SyncCoordinator` when synchronizing.
    ///
    /// We're only currently tracking one reason.
    enum SyncReason: String {
        case pullToRefresh = "pull_to_refresh"
    }

    let siteID: Int64
    /// The current filter mode of the Order List.
    let statusFilter: OrderStatus?

    /// Returns the action to use when synchronizing.
    func actionFor(pageNumber: Int,
                   pageSize: Int,
                   reason: SyncReason?,
                   completionHandler: @escaping (TimeInterval, Error?) -> Void) -> OrderAction {
        let statusKey = statusFilter?.slug

        if pageNumber == Defaults.pageFirstIndex {
            let deleteAllBeforeSaving = reason == SyncReason.pullToRefresh

            return OrderAction.fetchFilteredAndAllOrders(
                siteID: siteID,
                statusKey: statusKey,
                before: nil,
                deleteAllBeforeSaving: deleteAllBeforeSaving,
                pageSize: pageSize,
                onCompletion: completionHandler
            )
        }

        return OrderAction.synchronizeOrders(
            siteID: siteID,
            statusKey: statusKey,
            before: nil,
            pageNumber: pageNumber,
            pageSize: pageSize,
            onCompletion: completionHandler
        )
    }
}

extension OrderListSyncActionUseCase {
    enum Defaults {
        static let pageFirstIndex = SyncingCoordinator.Defaults.pageFirstIndex
    }
}
