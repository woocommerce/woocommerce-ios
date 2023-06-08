import Foundation

/// Tracks the waiting time for app startup, allowing to evaluate as analytics
/// how much time in seconds it took between the init and the final `end` function call
///
final class AppStartupWaitingTimeTracker: WaitingTimeTracker {
    /// Represents all of the app startup actions that are waiting to be completed.
    ///
    /// This begins with all app startup actions, with each action removed as it ends.
    ///
    private var appStartupWaitingActions = AppStartupAction.allCases

    /// All actions that must be waited for on app startup.
    ///
    enum AppStartupAction: CaseIterable {
        case appCoordinatorStart
        case restoreSessionSite
        case syncEntities
        case checkWooVersion
        case syncDashboardStats
        case syncJITMs
        case fetchExperimentAssignments
        case mainTabBarInit
    }

    init() {
        super.init(trackScenario: .appStartup)
    }

    /// End the waiting time for the provided startup action.
    /// If all startup actions are completed, evaluate the elapsed time from the init,
    /// and send it as an analytics event.
    ///
    func end(_ appStartupAction: AppStartupAction) {
        guard appStartupWaitingActions.isNotEmpty else {
            return
        }
        appStartupWaitingActions.removeAll { $0 == appStartupAction }
        if appStartupWaitingActions.isEmpty {
            print("*** App startup complete. ***")
            // TODO: Call super.end() to fire the analytics event
        }
    }
}
