import UIKit
import Yosemite

private enum StatsVersion: String {
    case v3 = "v3"
    case v4 = "v4"
}

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
    static func dashboardUI(siteID: Int,
                            onInitialUI: (DashboardUI) -> Void,
                            onUpdate: @escaping (DashboardUI) -> Void) {
        if FeatureFlag.stats.enabled {
            let lastStatsVersion = StatsVersion.v3

            let action = AvailabilityAction.checkStatsV4Availability(siteID: siteID) { isStatsV4Available in
                let statsVersion: StatsVersion = isStatsV4Available ? .v4: .v3
                if statsVersion != lastStatsVersion {
                    onUpdate(dashboardUI(statsVersion: statsVersion))
                }
            }
            ServiceLocator.stores.dispatch(action)

            let initialUI = dashboardUI(statsVersion: lastStatsVersion)
            onInitialUI(initialUI)
        } else {
            onInitialUI(DashboardStatsV3ViewController(nibName: nil, bundle: nil))
        }
    }

    private static func dashboardUI(statsVersion: StatsVersion) -> DashboardUI {
        switch statsVersion {
        case .v3:
            return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        case .v4:
            return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        }
    }
}
