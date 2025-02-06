import Foundation
import Combine
import protocol WooFoundation.Analytics

/// Tracks the waiting time for a given scenario, allowing to evaluate as analytics
/// how much time in seconds it took between the init and `end` function call
///
class WaitingTimeTracker {
    private let trackScenario: WooAnalyticsEvent.WaitingTime.Scenario
    private let currentTime: () -> TimeInterval
    private let analyticsService: Analytics
    private let waitingStartedTimestamp: TimeInterval

    init(trackScenario: WooAnalyticsEvent.WaitingTime.Scenario,
         analyticsService: Analytics = ServiceLocator.analytics,
         currentTime: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackScenario = trackScenario
        self.analyticsService = analyticsService
        self.currentTime = currentTime
        waitingStartedTimestamp = currentTime()
    }

    /// End the waiting time by evaluating the elapsed time from the init,
    /// and sending it as an analytics event, in seconds.
    ///
    func end() {
        let elapsedTime = currentTime() - waitingStartedTimestamp
        let analyticsEvent = WooAnalyticsEvent.WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime)
        analyticsService.track(event: analyticsEvent)
    }

    /// End the waiting time by evaluating the elapsed time from the init,
    /// and sending it as an analytics event, in milliseconds
    ///
    func endInMilliseconds() {
        let elapsedTimeMs = (currentTime() - waitingStartedTimestamp) * 1000
        let analyticsEvent = WooAnalyticsEvent.WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTimeMs)
        analyticsService.track(event: analyticsEvent)
    }
}
