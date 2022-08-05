import Foundation
import Combine

/// Tracks the waiting time for a given scenario, allowing to evaluate as analytics
/// how much time in seconds it took between the init and `end` function call
///
class WaitingTimeTracker {
    private let trackScenario: WooAnalyticsEvent.WaitingTime.Scenario
    private let currentTimeInMillis: () -> TimeInterval
    private let analyticsService: Analytics
    private let waitingStartedTimestamp: TimeInterval

    init(trackScenario: WooAnalyticsEvent.WaitingTime.Scenario,
         analyticsService: Analytics = ServiceLocator.analytics,
         currentTimeInMillis: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackScenario = trackScenario
        self.analyticsService = analyticsService
        self.currentTimeInMillis = currentTimeInMillis
        waitingStartedTimestamp = currentTimeInMillis()
    }

    /// End the waiting time by evaluating the elapsed time from the init,
    /// and sending it as an analytics event.
    ///
    func end() {
        let elapsedTime = currentTimeInMillis() - waitingStartedTimestamp
        let analyticsEvent = WooAnalyticsEvent.WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime)
        analyticsService.track(event: analyticsEvent)
    }
}
