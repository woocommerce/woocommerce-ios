import UIKit
import Storage
import Yosemite

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
    static func dashboardUIStatsVersion(isFeatureFlagOn: Bool,
                                        siteID: Int,
                                        onInitialUI: @escaping (_ statsVersion: StatsVersion) -> Void,
                                        onUpdate: @escaping (_ statsVersion: StatsVersion) -> Void) {
        if isFeatureFlagOn {
            let stores = ServiceLocator.stores

            let lastShownStatsVersionAction = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID) { lastShownStatsVersion in
                let lastStatsVersion: StatsVersion = lastShownStatsVersion ?? StatsVersion.v3
                onInitialUI(lastStatsVersion)

                let action = AvailabilityAction.checkStatsV4Availability(siteID: siteID) { isStatsV4Available in
                    let statsVersion: StatsVersion = isStatsV4Available ? .v4: .v3

                    if statsVersion != lastStatsVersion {
                        onUpdate(statsVersion)
                    }
                }
                stores.dispatch(action)
            }
            stores.dispatch(lastShownStatsVersionAction)
        } else {
            onInitialUI(.v3)
        }
    }

    static func createDashboardUIAndSetUserPreference(siteID: Int, statsVersion: StatsVersion) -> DashboardUI {
        let action = AppSettingsAction.setStatsVersionLastShown(siteID: siteID, statsVersion: statsVersion)
        ServiceLocator.stores.dispatch(action)

        switch statsVersion {
        case .v3:
            return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        case .v4:
            return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        }
    }
}
