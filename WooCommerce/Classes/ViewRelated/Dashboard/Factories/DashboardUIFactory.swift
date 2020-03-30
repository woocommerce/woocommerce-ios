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

    /// Reloads data in Dashboard
    ///
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(completion: @escaping () -> Void)
}

final class DashboardUIFactory {
    private let siteID: Int64
    private let stateCoordinator: StatsVersionStateCoordinator

    private var lastStatsV3DashboardUI: (DashboardUI & TopBannerPresenter)?
    private var lastStatsV4DashboardUI: DashboardUI?

    init(siteID: Int64) {
        self.siteID = siteID
        self.stateCoordinator = StatsVersionStateCoordinator(siteID: siteID)
    }

    func reloadDashboardUI(onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        stateCoordinator.onStateChange = { [weak self] (previousState, currentState) in
            self?.onStatsVersionStateChange(previousState: previousState,
                                            currentState: currentState,
                                            onUIUpdate: onUIUpdate)
        }
        stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
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
    func onStatsVersionStateChange(previousState: StatsVersionState?,
                                   currentState: StatsVersionState,
                                   onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        switch currentState {
        case .initial(let statsVersion), .eligible(let statsVersion):
            saveLastShownStatsVersion(statsVersion)

            let updatedDashboardUI = dashboardUI(statsVersion: statsVersion)
            onUIUpdate(updatedDashboardUI)

            if let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter {
                topBannerPresenter.hideTopBanner(animated: true)
            }
        case .v3ShownV4Eligible:
            let updatedDashboardUI = statsV3DashboardUI()
            onUIUpdate(updatedDashboardUI)

            guard previousState != currentState else {
                return
            }

            let topBannerView = DashboardTopBannerFactory.v3ToV4BannerView(actionHandler: { [weak self] in
                ServiceLocator.analytics.track(.dashboardNewStatsAvailabilityBannerTryTapped)
                self?.stateCoordinator.statsV4ButtonPressed()
                }, dismissHandler: { [weak self] in
                    ServiceLocator.analytics.track(.dashboardNewStatsAvailabilityBannerCancelTapped)
                    self?.stateCoordinator.dismissV3ToV4Banner()
            })
            updatedDashboardUI.hideTopBanner(animated: false)
            updatedDashboardUI.showTopBanner(topBannerView)
        case .v4RevertedToV3:
            saveLastShownStatsVersion(.v3)

            let updatedDashboardUI = statsV3DashboardUI()
            onUIUpdate(updatedDashboardUI)

            guard previousState != currentState else {
                return
            }

            let topBannerView = DashboardTopBannerFactory.v4ToV3BannerView(actionHandler: {
                guard let url = URL(string: "https://wordpress.org/plugins/woocommerce-admin/") else {
                    return
                }
                ServiceLocator.analytics.track(.dashboardNewStatsRevertedBannerLearnMoreTapped)
                WebviewHelper.launch(url, with: updatedDashboardUI)
            }, dismissHandler: { [weak self] in
                ServiceLocator.analytics.track(.dashboardNewStatsRevertedBannerDismissTapped)
                self?.stateCoordinator.dismissV4ToV3Banner()
            })
            updatedDashboardUI.hideTopBanner(animated: false)
            updatedDashboardUI.showTopBanner(topBannerView)
        }
    }
}
