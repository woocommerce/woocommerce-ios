import Foundation

class MockScheduler: Scheduler {
    var scheduledActions: [(TimeInterval, () -> Void, MockCancellable)] = []

    func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> Cancellable {
        let cancellable = MockCancellable()
        scheduledActions.append((seconds, action, cancellable))
        return cancellable
    }

    func runNextAction() {
        guard let (_, action, _) = scheduledActions.first else { return }
        action()
        scheduledActions.removeFirst()
    }
}

class MockCancellable: Cancellable {
    var isCancelled = false
    func cancel() {
        isCancelled = true
    }
}
