import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval

    @Published private(set) var currentState: State = .idle

    private var waitingTimer: Timer? = nil
    private var subscriptions: Set<AnyCancellable> = []

    /// Initialize the WaitingTimeTracker with a specific timeout, if none is provided it will set 30 seconds as the default
    ///
    init(waitingTimeout: TimeInterval = 30) {
        self.waitingTimeout = waitingTimeout
        configureCurrentState()
    }

    /// Configure the state changes and react to the specified one
    /// - `.done`: Will send the elapsed waiting time to the Tracks
    /// - `.waiting`: Will trigger the timeout Timer and wait for the `.done` state to sink
    /// - `.idle`: Does nothing and breaks the state changing cycle
    ///
    private func configureCurrentState() {
        $currentState
            .removeDuplicates()
            .sink { [weak self] state in
                switch state {
                case .done(let waitingEndedTime):
                    self?.sendWaitingTimeToTracks(
                            waitingEndedTime: waitingEndedTime
                    )
                    self?.resetTrackerState()
                case .waiting:
                    self?.startWaitingTimer()
                case .idle:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    /// Set the Tracker state to `.waiting`, triggering the waiting cycle
    ///
    /// - parameter analyticsStat: The stat to be send to Tracks when the waiting time ends
    ///
    func onWaitingStarted(analyticsStat: WooAnalyticsStat) {
        currentState = .waiting(NSDate().timeIntervalSince1970, analyticsStat)
    }
    
    /// Set the Tracker state to `.done`, ending the waiting cycle. Only accepts it if the current state is `.waiting`
    /// otherwise, it will ignore the call
    ///
    func onWaitingEnded() {
        guard case .waiting = currentState else {
            return
        }

        currentState = .done(NSDate().timeIntervalSince1970)
    }

    /// Calculates the elapsed time with the difference between the `.done` and `.waiting` time interval
    /// and send it to Tracks with the provided AnalyticsStat, given that the `currentState` is `.waiting`.
    ///
    /// Will only submit the elapsed time if it's higher than zero and lower than the expected waiting timeout.
    ///
    /// - parameter waitingEndedTime: The time interval of when the waiting ended.
    ///
    private func sendWaitingTimeToTracks(waitingEndedTime: TimeInterval) {
        guard case .waiting(let waitingStartedTime, let analyticsStat) = currentState else {
            return
        }

        let elapsedTime = waitingEndedTime - waitingStartedTime
        if 0.0...waitingTimeout ~= elapsedTime {
            ServiceLocator.analytics.track(analyticsStat, withProperties: [
                "waiting_time": elapsedTime
            ])
        }
    }

    /// The timeout timer that will cancel the waiting state and return the Tracker to `.idle`.
    /// Can be cancelled through the `waitingTimer` reference when the waiting is done.
    ///
    private func startWaitingTimer() {
        waitingTimer = Timer.scheduledTimer(
                withTimeInterval: waitingTimeout,
                repeats: false) { [weak self] timer in
                    self?.resetTrackerState()
        }
    }

    /// Resets the Tracker state to `.idle` and cancel the timeout timer, configuring everything to the start point
    ///
    private func resetTrackerState() {
        waitingTimer?.invalidate()
        waitingTimer = nil
        currentState = .idle
    }

    enum State: Equatable {
        case idle
        case waiting(TimeInterval, WooAnalyticsStat)
        case done(TimeInterval)
    }
}
