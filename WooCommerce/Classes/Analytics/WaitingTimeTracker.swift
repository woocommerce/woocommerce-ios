import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval

    @Published private(set) var currentState: State = .idle

    private var waitingTimer: Timer? = nil
    private var subscriptions: Set<AnyCancellable> = []

    init(waitingTimeout: TimeInterval = 30000) {
        self.waitingTimeout = waitingTimeout
        configureCurrentState()
    }

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

    func onWaitingStarted(analyticsEvent: WooAnalyticsEvent) {
        currentState = .waiting(NSDate().timeIntervalSince1970, analyticsEvent)
    }

    func onWaitingEnded() {
        guard case .waiting = currentState else {
            return
        }

        currentState = .done(NSDate().timeIntervalSince1970)
    }

    private func sendWaitingTimeToTracks(waitingEndedTime: TimeInterval) {
        guard case .waiting(let waitingStartedTime, let analyticsEvent) = currentState else {
            return
        }

        let elapsedTime = waitingEndedTime - waitingStartedTime
        // send elapsedTime tracks
    }

    private func startWaitingTimer() {
        waitingTimer = Timer.scheduledTimer(
                withTimeInterval: waitingTimeout,
                repeats: false) { [weak self] timer in
                    self?.resetTrackerState()
        }
    }

    private func resetTrackerState() {
        waitingTimer?.invalidate()
        waitingTimer = nil
        currentState = .idle
    }

    enum State: Equatable {
        case idle
        case waiting(TimeInterval, WooAnalyticsEvent)
        case done(TimeInterval)
    }
}
