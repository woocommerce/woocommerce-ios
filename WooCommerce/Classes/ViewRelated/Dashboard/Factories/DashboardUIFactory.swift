import UIKit

/// Contains all UI content to show on Dashboard
///
protocol DashboardUI: UIViewController {
    /// Called when the Dashboard should display syncing error
    var displaySyncingErrorNotice: () -> Void { get set }

    /// Called when the user pulls to refresh
    var onPullToRefresh: () -> Void { get set }

    /// Called when the default account was updated
    func defaultAccountDidUpdate()

    /// Reloads data in Dashboard
    ///
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(completion: @escaping () -> Void)
}

final class DashboardUIFactory {
    static func dashboardUI() -> DashboardUI {
        if FeatureFlag.stats.enabled {
            return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        } else {
            return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        }
    }
}
