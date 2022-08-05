import Foundation
import Combine

class WaitingTimeTracker {
    private let trackScenario: WooAnalyticsEvent.WaitingTime.Scenario
    private let currentTimeInMillis: () -> TimeInterval
    private let analyticsService: Analytics

    private var waitingStartedTimestamp: TimeInterval? = nil

    /// Initialize the WaitingTimeTracker with a specific timeout, if none is provided it will set 30 seconds as the default
    ///
    init(trackScenario: WooAnalyticsEvent.WaitingTime.Scenario,
         analyticsService: Analytics = ServiceLocator.analytics,
         currentTimeInMillis: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackScenario = trackScenario
        self.analyticsService = analyticsService
        self.currentTimeInMillis = currentTimeInMillis
    }

    /// Set the Tracker state to `.waiting`, triggering the waiting cycle
    ///
    /// - parameter analyticsStat: The stat to be send to Tracks when the waiting time ends
    ///
    func onWaitingStarted(analyticsStat: WooAnalyticsStat) {
        waitingStartedTimestamp = currentTimeInMillis()
    }

    /// Set the Tracker state to `.done`, ending the waiting cycle. Only accepts it if the current state is `.waiting`
    /// otherwise, it will ignore the call
    ///
    func onWaitingEnded() {
        guard let waitingStartedTimestamp = waitingStartedTimestamp else {
            return
        }

        let elapsedTime = currentTimeInMillis() - waitingStartedTimestamp
        let analyticsEvent = WooAnalyticsEvent.WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime)
        analyticsService.track(event: analyticsEvent)
    }
}
