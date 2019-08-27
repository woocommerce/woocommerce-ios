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
    private let stores: StoresManager
    private var stateCoordinator: StatsVersionStateCoordinator?

    private var lastStatsVersion: StatsVersion?
    private var lastDashboardUI: DashboardUI?

    init(siteID: Int, stores: StoresManager) {
        self.siteID = siteID
        self.stores = stores
    }

    func reloadDashboardUI(isFeatureFlagOn: Bool,
                           onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        if isFeatureFlagOn {
            let stateCoordinator = StatsVersionStateCoordinator(siteID: siteID,
                                                                stores: stores,
                                                                onStateChange: { [weak self] state in
                                                                    guard let self = self else {
                                                                        return
                                                                    }
                                                                    self.onStatsVersionStateChange(state: state, onUIUpdate: onUIUpdate)
            })
            self.stateCoordinator = stateCoordinator
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
    func onStatsVersionStateChange(state: StatsVersionState, onUIUpdate: @escaping (_ dashboardUI: DashboardUI) -> Void) {
        switch state {
        case .initial(let statsVersion), .eligible(let statsVersion):
            onUIUpdate(dashboardUI(siteID: siteID, statsVersion: statsVersion))
        case .v3ShownV4Eligible:
            // TODO-1232: handle v3 --> v4 upgrading: shows top banner to announce stats v4 feature for user to opt in.
            onUIUpdate(dashboardUI(siteID: siteID, statsVersion: .v4))
        case .v4RevertedToV3:
            // TODO-1232: handle v4 --> v3 downgrading: reverts dashboard UI to v3 and shows top banner with explanations.
            onUIUpdate(dashboardUI(siteID: siteID, statsVersion: .v3))
        }
    }
}
