import Foundation
import Combine

class WaitingTimeTracker {
    @Published var currentState: State = .idle(0.0)

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
