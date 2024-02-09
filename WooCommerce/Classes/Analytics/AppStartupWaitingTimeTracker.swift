import Foundation
import Yosemite

/// Tracks the waiting time for app startup, allowing to evaluate as analytics
/// how much time in seconds it took between the init and the final `end(action:)` function call.
///
class AppStartupWaitingTimeTracker: WaitingTimeTracker {

    /// All actions tracked in the app startup waiting time.
    ///
    /// This should include any actions that contribute to the **perceived** initial loading time on the dashboard.
    ///
    enum StartupAction: CaseIterable {
        case syncDashboardStats
        case loadOnboardingTasks
        case syncBlazeCampaigns
    }

    /// Represents all of the app startup actions waiting to be completed.
    ///
    private(set) var startupActionsPending = StartupAction.allCases

    /// A lock to ensure that the tracker only modifies the pending startup actions one at a time.
    ///
    private var lock = NSLock()

    init(analyticsService: Analytics = ServiceLocator.analytics,
         currentTimeInMillis: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        super.init(trackScenario: .appStartup, analyticsService: analyticsService, currentTimeInMillis: currentTimeInMillis)
    }

    /// Ends the waiting time for the provided startup action.
    /// If all startup actions are completed, evaluate the elapsed time from the init,
    /// and send it as an analytics event.
    ///
    func end(action: StartupAction) {
        lock.lock()
        defer { lock.unlock() }

        // Ignore any actions after the pending startup actions are complete.
        guard startupActionsPending.isNotEmpty else {
            return
        }

        startupActionsPending.removeAll { $0 == action }

        // If all actions completed without any errors, send the analytics event.
        if startupActionsPending.isEmpty {
            super.end()
        }
    }

    /// Ends the tracker without sending an analytics event.
    ///
    /// This can be used to stop tracking in scenarios that would skew the waiting time analysis.
    /// For example, when the app is backgrounded or a startup action has an API error or network connection error.
    ///
    override func end() {
        lock.lock()
        defer { lock.unlock() }

        startupActionsPending.removeAll()
    }
}
