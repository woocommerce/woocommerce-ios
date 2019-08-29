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
    private let siteID: Int
    private let stateCoordinator: StatsVersionStateCoordinator

    private var lastStatsVersion: StatsVersion?
    private var lastDashboardUI: DashboardUI?

    init(siteID: Int) {
        self.siteID = siteID
        self.stateCoordinator = StatsVersionStateCoordinator(siteID: siteID)
    }

    func reloadDashboardUI(isFeatureFlagOn: Bool,
                           onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        if isFeatureFlagOn {
            stateCoordinator.onStateChange = { [weak self] (previousState, currentState) in
                self?.onStatsVersionStateChange(previousState: previousState,
                                                currentState: currentState,
                                                onUIUpdate: onUIUpdate)
            }
            stateCoordinator.loadLastShownVersionAndCheckV4Eligibility()
        } else {
            onUIUpdate(dashboardUI(siteID: siteID, statsVersion: .v3))
        }
    }

    private func dashboardUI(siteID: Int, statsVersion: StatsVersion) -> DashboardUI {
        if let lastDashboardUI = lastDashboardUI, lastStatsVersion == statsVersion {
            return lastDashboardUI
        }
        return createDashboardUIAndSetUserPreference(siteID: siteID, statsVersion: statsVersion)
    }

    private func createDashboardUIAndSetUserPreference(siteID: Int, statsVersion: StatsVersion) -> DashboardUI {
        let action = AppSettingsAction.setStatsVersionLastShown(siteID: siteID, statsVersion: statsVersion)
        ServiceLocator.stores.dispatch(action)

        let dashboardUI = createDashboardUI(statsVersion: statsVersion)

        lastStatsVersion = statsVersion
        lastDashboardUI = dashboardUI

        return dashboardUI
    }

    private func createDashboardUI(statsVersion: StatsVersion) -> DashboardUI {
        switch statsVersion {
        case .v3:
            return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
        case .v4:
            return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
        }
    }
}

private extension DashboardUIFactory {
    func onStatsVersionStateChange(previousState: StatsVersionState?,
                                   currentState: StatsVersionState,
                                   onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        switch currentState {
        case .initial(let statsVersion), .eligible(let statsVersion):
            let updatedDashboardUI = dashboardUI(siteID: siteID, statsVersion: statsVersion)
            onUIUpdate(updatedDashboardUI)

            if let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter {
                topBannerPresenter.hideTopBanner(animated: true)
            }
        case .v3ShownV4Eligible:
            let updatedDashboardUI = dashboardUI(siteID: siteID, statsVersion: .v3)
            onUIUpdate(updatedDashboardUI)

            guard previousState != currentState else {
                return
            }

            guard let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter else {
                assertionFailure("Dashboard UI \(updatedDashboardUI.self) should be able to present top banner")
                return
            }

            let topBannerView = DashboardTopBannerFactory.v3ToV4BannerView(actionHandler: { [weak self] in
                self?.stateCoordinator.statsV4ButtonPressed()
                }, dismissHandler: { [weak self] in
                    self?.stateCoordinator.dismissV3ToV4Banner()
            })
            topBannerPresenter.hideTopBanner(animated: false)
            topBannerPresenter.showTopBanner(topBannerView)
        case .v4RevertedToV3:
            let updatedDashboardUI = dashboardUI(siteID: siteID, statsVersion: .v3)
            onUIUpdate(updatedDashboardUI)

            guard previousState != currentState else {
                return
            }
            
            guard let topBannerPresenter = updatedDashboardUI as? TopBannerPresenter else {
                assertionFailure("Dashboard UI \(updatedDashboardUI.self) should be able to present top banner")
                return
            }

            let topBannerView = DashboardTopBannerFactory.v4ToV3BannerView(actionHandler: {
                guard let url = URL(string: "https://wordpress.org/plugins/woocommerce-admin/") else {
                    return
                }
                WebviewHelper.launch(url, with: updatedDashboardUI)
            }, dismissHandler: { [weak self] in
                self?.stateCoordinator.dismissV4ToV3Banner()
            })
            topBannerPresenter.hideTopBanner(animated: false)
            topBannerPresenter.showTopBanner(topBannerView)
        }
    }
}
