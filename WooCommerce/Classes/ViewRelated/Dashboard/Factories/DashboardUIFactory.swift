import Storage
import UIKit
import Yosemite
import Experiments

/// Contains all UI content to show on Dashboard
///
protocol DashboardUI: UIViewController {
    /// For navigation bar large title workaround.
    var scrollDelegate: DashboardUIScrollDelegate? { get set }

    /// Called when the Dashboard should display syncing error
    var displaySyncingError: () -> Void { get set }

    /// Called when the user pulls to refresh
    var onPullToRefresh: () -> Void { get set }

    /// Reloads data in Dashboard
    ///
    /// - Parameter forced: pass `true` to override sync throttling
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(forced: Bool, completion: @escaping () -> Void)
}

/// Relays the scroll events to a delegate for navigation bar large title workaround.
protocol DashboardUIScrollDelegate: AnyObject {
    /// Called when a dashboard tab `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    func dashboardUIScrollViewDidScroll(_ scrollView: UIScrollView)
}

final class DashboardUIFactory {
    private let siteID: Int64
    private let statsVersionCoordinator: StatsVersionCoordinator

    private var lastStatsV4DashboardUI: DashboardUI?
    private lazy var deprecatedStatsViewController = DeprecatedDashboardStatsViewController()
    private let featureFlagService: FeatureFlagService

    init(siteID: Int64, currentDateProvider: @escaping () -> Date = Date.init, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.statsVersionCoordinator = StatsVersionCoordinator(siteID: siteID)
        self.featureFlagService = featureFlagService
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
        let dashboardUI: DashboardUI
        if featureFlagService.isFeatureFlagEnabled(.myStoreTabUpdates) {
            dashboardUI = StoreStatsAndTopPerformersViewController(siteID: siteID)
        } else {
            dashboardUI = OldStoreStatsAndTopPerformersViewController(siteID: siteID)
        }
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
