import Foundation

import enum Yosemite.OrderAction
import struct Yosemite.OrderStatus

/// Returns what `OrderAction` should be used when synchronizing a list of orders.
///
/// This is meant to be used by `OrderListViewModel` (and the deprecated `OrdersViewModel`).
///
/// ## Discussion
///
/// Pulling to refresh on filtered lists, will perform 1 network GET
/// requests with the filters applied (status or date ranges)
///
/// eg. Fetch the /orders?status=processed
///
/// We will also delete all the orders before saving the new fetched ones.
///
/// We are currently doing this to avoid showing stale orders to users (https://git.io/JvMME).
/// An example scenario is:
///
/// 1. Load the Orders tab.
/// 2. In the web, change one of the _processing_ orders to a different status (e.g. completed).
/// 3. Pull to refresh.
///
/// If we were only doing one query, we would be fetching `GET /orders?status=processed` only.
/// But that doesn't include the old order which was changed to a different status and is no
/// longer in the response list. Hence, that updated order will stay on the tab and is stale.
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
struct OrderListSyncActionUseCase {

    /// The reasons passed to `SyncCoordinator` when synchronizing.
    ///
    enum SyncReason: String {
        case newFiltersApplied = "new_filters_applied"
        case pullToRefresh = "pull_to_refresh"
        case viewWillAppear = "view_will_appear"
    }

    let siteID: Int64
    /// The current filters applied to the Order List
    let filters: FilterOrderListViewModel.Filters?

    /// Returns the action to use when synchronizing.
    func actionFor(pageNumber: Int,
                   pageSize: Int,
                   reason: SyncReason?,
                   completionHandler: @escaping (TimeInterval, Error?) -> Void) -> OrderAction {
        let statusKey = filters?.orderStatus?.rawValue
        let startDate = filters?.dateRange?.computedStartDate
        let endDate = filters?.dateRange?.computedEndDate

        if pageNumber == Defaults.pageFirstIndex {
            let deleteAllBeforeSaving = reason == SyncReason.pullToRefresh || reason == SyncReason.newFiltersApplied

            return OrderAction.fetchFilteredOrders(
                siteID: siteID,
                statusKey: statusKey,
                after: startDate,
                before: endDate,
                deleteAllBeforeSaving: deleteAllBeforeSaving,
                pageSize: pageSize,
                onCompletion: completionHandler
            )
        }

        return OrderAction.synchronizeOrders(
            siteID: siteID,
            statusKey: statusKey,
            after: startDate,
            before: endDate,
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
