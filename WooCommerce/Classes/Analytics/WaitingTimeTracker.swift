import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval
    private let trackEvent: WooAnalyticsStat

    private var waitingStartedTimestamp: TimeInterval? = nil

    /// Initialize the WaitingTimeTracker with a specific timeout, if none is provided it will set 30 seconds as the default
    ///
    init(trackEvent: WooAnalyticsStat, waitingTimeout: TimeInterval = 30) {
        self.waitingTimeout = waitingTimeout
        self.trackEvent = trackEvent
    }

    /// Set the Tracker state to `.waiting`, triggering the waiting cycle
    ///
    /// - parameter analyticsStat: The stat to be send to Tracks when the waiting time ends
    ///
    func onWaitingStarted(analyticsStat: WooAnalyticsStat) {
        waitingStartedTimestamp = NSDate().timeIntervalSince1970
    }

    /// Set the Tracker state to `.done`, ending the waiting cycle. Only accepts it if the current state is `.waiting`
    /// otherwise, it will ignore the call
    ///
    func onWaitingEnded() {
        guard let waitingStartedTimestamp = waitingStartedTimestamp else {
            return
        }

        let elapsedTime = NSDate().timeIntervalSince1970 - waitingStartedTimestamp
        ServiceLocator.analytics.track(trackEvent, withProperties: [
            "waiting_time": elapsedTime
        ])
    }
}
