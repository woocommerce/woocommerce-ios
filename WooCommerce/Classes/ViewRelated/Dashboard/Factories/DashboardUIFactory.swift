import Storage
import UIKit
import Yosemite

/// Contains all UI content to show on Dashboard
///
protocol DashboardUI: UIViewController {
    /// For navigation bar large title workaround.
    var scrollDelegate: DashboardUIScrollDelegate? { get set }

    /// Called when the Dashboard should display syncing error
    var displaySyncingErrorNotice: () -> Void { get set }

    /// Called when the user pulls to refresh
    var onPullToRefresh: () -> Void { get set }

    /// Reloads data in Dashboard
    ///
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(completion: @escaping () -> Void)
}

/// Relays the scroll events to a delegate for navigation bar large title workaround.
protocol DashboardUIScrollDelegate: class {
    /// Called when a dashboard tab `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    func dashboardUIScrollViewDidScroll(_ scrollView: UIScrollView)
}

final class DashboardUIFactory {
    private let siteID: Int64
    private let statsVersionCoordinator: StatsVersionCoordinator

    private var lastStatsV4DashboardUI: DashboardUI?
    private lazy var deprecatedStatsViewController = DeprecatedDashboardStatsViewController()

    init(siteID: Int64, currentDateProvider: @escaping () -> Date = Date.init) {
        self.siteID = siteID
        self.statsVersionCoordinator = StatsVersionCoordinator(siteID: siteID)
    }

    func reloadDashboardUI(onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        statsVersionCoordinator.onVersionChange = { [weak self] (previousVersion, currentVersion) in
            self?.onStatsVersionChange(previousVersion: previousVersion,
                                       currentVersion: currentVersion,
                                       onUIUpdate: onUIUpdate)
        }
        statsVersionCoordinator.loadLastShownVersionAndCheckV4Eligibility()
    }

    private func statsV4DashboardUI() -> DashboardUI {
        if let lastStatsV4DashboardUI = lastStatsV4DashboardUI {
            return lastStatsV4DashboardUI
        }
        let dashboardUI = StoreStatsAndTopPerformersViewController(siteID: siteID)
        lastStatsV4DashboardUI = dashboardUI
        return dashboardUI
    }

    private func dashboardUI(statsVersion: StatsVersion) -> DashboardUI {
        switch statsVersion {
        case .v3:
            // Return an stats-empty view controller for v3 stats
            return deprecatedStatsViewController
        case .v4:
            return statsV4DashboardUI()
        }
    }

    private func saveLastShownStatsVersion(_ lastShownStatsVersion: StatsVersion) {
        let action = AppSettingsAction.setStatsVersionLastShown(siteID: siteID, statsVersion: lastShownStatsVersion)
        ServiceLocator.stores.dispatch(action)
    }
}

private extension DashboardUIFactory {
    func onStatsVersionChange(previousVersion: StatsVersion?,
                              currentVersion: StatsVersion,
                              onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        saveLastShownStatsVersion(currentVersion)

        let updatedDashboardUI = dashboardUI(statsVersion: currentVersion)
        onUIUpdate(updatedDashboardUI)
    }
}
