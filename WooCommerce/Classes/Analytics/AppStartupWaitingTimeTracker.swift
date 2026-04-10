import Foundation
import Yosemite
import class WooFoundation.WaitingTimeTracker
import protocol WooFoundation.Analytics

/// Tracks the waiting time for app startup, allowing to evaluate as analytics
/// how much time in seconds it took between the init and the final `end(action:)` function call.
///
final class AppStartupWaitingTimeTracker {

    /// All actions tracked in the app startup waiting time.
    ///
    /// This should include any actions that contribute to the **perceived** initial loading time on the dashboard.
    ///
    enum StartupAction: CaseIterable {
        case syncDashboardStats
        case loadOnboardingTasks
    }

    /// Represents all of the app startup actions waiting to be completed.
    ///
    private(set) var startupActionsPending = StartupAction.allCases
    private let analyticsService: Analytics
    private let waitingTimeTracker: WaitingTimeTracker

    init(analyticsService: Analytics = ServiceLocator.analytics,
         currentTimestampSeconds: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.analyticsService = analyticsService
        self.waitingTimeTracker = WaitingTimeTracker(trackScenario: .appStartup, currentTimestampSeconds: currentTimestampSeconds)
    }

    /// Ends the waiting time for the provided startup action.
    /// If all startup actions are completed, evaluate the elapsed time from the init,
    /// and send it as an analytics event.
    ///
    func end(action: StartupAction) {
        // Ignore any actions after the pending startup actions are complete.
        guard startupActionsPending.isNotEmpty else {
            return
        }

        startupActionsPending.removeAll { $0 == action }

        // If all actions completed without any errors, send the analytics event.
        if startupActionsPending.isEmpty {
            analyticsService.track(event: waitingTimeTracker.end())
        }
    }

    /// Ends the tracker without sending an analytics event.
    ///
    /// This can be used to stop tracking in scenarios that would skew the waiting time analysis.
    /// For example, when the app is backgrounded or a startup action has an API error or network connection error.
    ///
    func endWithoutTracking() {
        startupActionsPending.removeAll()
    }
}
