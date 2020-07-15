import Storage
import UIKit
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

    /// Called when the user has decided to not be bothered with the deprecated stats banner right now.
    func remindStatsUpgradeLater()

    /// Reloads data in Dashboard
    ///
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(completion: @escaping () -> Void)
}

final class DashboardUIFactory {
    private let siteID: Int64
    private let statsVersionCoordinator: StatsVersionCoordinator

    /// Function that generates the current system date
    private let currentDateProvider: () -> Date

    private var lastStatsV3DashboardUI: (DashboardUI & TopBannerPresenter)?
    private var lastStatsV4DashboardUI: DashboardUI?
    private lazy var deprecatedStatsViewController = DeprecatedDashboardStatsViewController()

    init(siteID: Int64, currentDateProvider: @escaping () -> Date = Date.init) {
        self.siteID = siteID
        self.statsVersionCoordinator = StatsVersionCoordinator(siteID: siteID)
        self.currentDateProvider = currentDateProvider
    }

    func reloadDashboardUI(onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        statsVersionCoordinator.onVersionChange = { [weak self] (previousVersion, currentVersion) in
            self?.onStatsVersionChange(previousVersion: previousVersion,
                                       currentVersion: currentVersion,
                                       onUIUpdate: onUIUpdate)
        }
        statsVersionCoordinator.loadLastShownVersionAndCheckV4Eligibility()
    }

    private func statsV3DashboardUI() -> DashboardUI & TopBannerPresenter {
        if let lastStatsV3DashboardUI = lastStatsV3DashboardUI {
            return lastStatsV3DashboardUI
        }
        let dashboardUI = DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        lastStatsV3DashboardUI = dashboardUI
        return dashboardUI
    }

    private func statsV4DashboardUI() -> DashboardUI {
        if let lastStatsV4DashboardUI = lastStatsV4DashboardUI {
            return lastStatsV4DashboardUI
        }
        let dashboardUI = StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        lastStatsV4DashboardUI = dashboardUI
        return dashboardUI
    }

    private func dashboardUI(statsVersion: StatsVersion) -> DashboardUI {
        switch statsVersion {
        case .v3:
            // Return an stats-empty view controller if current system date is greater than our deprecation trigger date(09/01/2020)
            if let deprecatedStatsDate = Date.september1st2020, currentDateProvider() > deprecatedStatsDate {
                return deprecatedStatsViewController
            }
            return statsV3DashboardUI()
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

        if let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter {
            switch currentVersion {
            case .v3:
                let topBannerView = DashboardTopBannerFactory.deprecatedStatsBannerView {
                    updatedDashboardUI.remindStatsUpgradeLater()
                }
                topBannerPresenter.hideTopBanner(animated: false)
                topBannerPresenter.showTopBanner(topBannerView)
            case .v4:
                topBannerPresenter.hideTopBanner(animated: true)
            }
        }
    }
}

private extension Date {

    /// Returns a date object that corresponds to September 1st of 2020
    static var september1st2020: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 9
        dateComponents.day = 1

        return Calendar.current.date(from: dateComponents)
    }
}
