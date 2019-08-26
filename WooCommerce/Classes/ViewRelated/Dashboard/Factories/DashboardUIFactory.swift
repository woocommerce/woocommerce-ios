import UIKit
import Yosemite

enum StatsVersion: String {
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
    static func dashboardUIStatsVersion(siteID: Int,
                                        onInitialUI: (_ statsVersion: StatsVersion) -> Void,
                                        onUpdate: @escaping (_ statsVersion: StatsVersion) -> Void) {
        if FeatureFlag.stats.enabled {
            let userDefaults = UserDefaults.standard
            let lastStatsVersionString: String? = userDefaults.object(forKey: .statsVersionLastSeen)
            let lastStatsVersion: StatsVersion = lastStatsVersionString.flatMap({ StatsVersion(rawValue: $0) })
                ?? StatsVersion.v3

            let action = AvailabilityAction.checkStatsV4Availability(siteID: siteID) { isStatsV4Available in
                let statsVersion: StatsVersion = isStatsV4Available ? .v4: .v3
                UserDefaults.standard.set(statsVersion.rawValue, forKey: .statsVersionEligible)
                if statsVersion != lastStatsVersion {
                    onUpdate(statsVersion)
                }
            }
            ServiceLocator.stores.dispatch(action)

            onInitialUI(lastStatsVersion)
        } else {
            onInitialUI(.v3)
        }
    }

    static func createDashboardUIForDisplay(statsVersion: StatsVersion) -> DashboardUI {
        saveLastSeenStatsVersion(statsVersion)
        switch statsVersion {
        case .v3:
            return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        case .v4:
            return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        }
    }

    /// Sets the last seen stats version to user defaults.
    /// Called when the dashboard UI of a stats version is shown to the user.
    private static func saveLastSeenStatsVersion(_ statsVersion: StatsVersion) {
        UserDefaults.standard.set(statsVersion.rawValue, forKey: .statsVersionLastSeen)
    }
}
