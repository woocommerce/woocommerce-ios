import Foundation
import Combine

class WaitingTimeTracker {
    private let trackEvent: WooAnalyticsStat
    private let currentTimeInMillis: () -> TimeInterval

    private var waitingStartedTimestamp: TimeInterval? = nil

    /// Initialize the WaitingTimeTracker with a specific timeout, if none is provided it will set 30 seconds as the default
    ///
    init(trackEvent: WooAnalyticsStat,
         currentTimeInMillis: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackEvent = trackEvent
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
        ServiceLocator.analytics.track(trackEvent, withProperties: [
            "waiting_time": elapsedTime
        ])
    }
}
