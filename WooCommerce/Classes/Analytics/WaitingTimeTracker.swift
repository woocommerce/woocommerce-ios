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
