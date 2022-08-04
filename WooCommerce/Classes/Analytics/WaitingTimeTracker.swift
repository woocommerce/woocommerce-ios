import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval

    @Published var currentState: State = .idle(0.0)

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
            currentState = .idle(0.0)
        }
    }

    func onWaitingEnded() {
    }

    enum State {
        let creationTimestamp: TimeInterval

        init(creationTimestamp: TimeInterval? = nil) {
            self.creationTimestamp = creationTimestamp ?? NSDate().timeIntervalSince1970
        }

        case idle
        case waiting
        case done
    }
}
