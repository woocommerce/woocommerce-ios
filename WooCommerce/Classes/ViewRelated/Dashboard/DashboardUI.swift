import UIKit

/// Contains all UI content to show on Dashboard
///
protocol DashboardUI: UIViewController {
    /// For navigation bar large title workaround.
    var scrollDelegate: DashboardUIScrollDelegate? { get set }

    /// Called when the Dashboard should display syncing error
    var displaySyncingError: () -> Void { get set }

    /// Called when the user pulls to refresh
    var onPullToRefresh: () async -> Void { get set }

    /// Reloads data in Dashboard
    ///
    /// - Parameter forced: pass `true` to override sync throttling
    func reloadData(forced: Bool) async
}

/// Relays the scroll events to a delegate for navigation bar large title workaround.
protocol DashboardUIScrollDelegate: AnyObject {
    /// Called when a dashboard tab `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    func dashboardUIScrollViewDidScroll(_ scrollView: UIScrollView)
}
