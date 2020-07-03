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

    /// Called when the user has decided to not be bother with the deprecated stats banner right now.
    func remindStatsUpgradeLater()

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
        case .initial(let statsVersion):
            saveLastShownStatsVersion(statsVersion)

            let updatedDashboardUI = dashboardUI(statsVersion: statsVersion)
            onUIUpdate(updatedDashboardUI)

            if let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter {
                switch statsVersion {
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
}
