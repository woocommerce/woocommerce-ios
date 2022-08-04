import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval

    @Published private(set) var currentState: State = .idle

    private var waitingTimer: Timer? = nil

    init(waitingTimeout: TimeInterval = 30000) {
        self.waitingTimeout = waitingTimeout
    }

    func onWaitingStarted() {
        currentState = .waiting(NSDate().timeIntervalSince1970)
        waitingTimer = Timer.scheduledTimer(
                withTimeInterval: waitingTimeout,
                repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.waitingTimer = nil
            currentState = .idle
        }
    }

    func onWaitingEnded() {
        if currentState == .waiting {
            currentState = .done(NSDate().timeIntervalSince1970)
        }
    }

    enum State {
        case idle
        case waiting(TimeInterval)
        case done(TimeInterval)
    }
}
