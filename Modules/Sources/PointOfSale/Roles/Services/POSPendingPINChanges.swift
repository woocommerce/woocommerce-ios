import Foundation

@MainActor
final class POSPendingPINChanges {
    private var pendingChanges = 0
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    nonisolated init() {}

    var isEmpty: Bool {
        pendingChanges == 0
    }

    func begin() -> POSPINChangeRegistration {
        pendingChanges += 1
        return POSPINChangeRegistration { self.finish() }
    }

    func waitUntilEmpty() async {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard pendingChanges > 0, !Task.isCancelled else {
                    return continuation.resume()
                }
                waiters[id] = continuation
            }
        } onCancel: {
            Task { @MainActor in self.waiters.removeValue(forKey: id)?.resume() }
        }
    }

    private func finish() {
        pendingChanges -= 1
        guard pendingChanges == 0 else {
            return
        }
        let waiting = waiters.values
        waiters = [:]
        waiting.forEach { $0.resume() }
    }
}

@MainActor
final class POSPINChangeRegistration {
    private var onFinish: (() -> Void)?

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func finish() {
        let completion = onFinish
        onFinish = nil
        completion?()
    }
}
