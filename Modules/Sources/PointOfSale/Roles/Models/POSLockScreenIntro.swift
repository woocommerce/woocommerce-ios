import Observation
import SwiftUI

@Observable
@MainActor
final class POSLockScreenIntro {
    enum Phase {
        case appearing, closing, revealing, finished
    }

    private(set) var phase = Phase.appearing
    @ObservationIgnored private var animationTask: Task<Void, Never>?
    private let sleep: @MainActor (Duration) async throws -> Void

    init(sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    func run(shouldAnimate: Bool) async {
        if let animationTask {
            await animationTask.value
            return
        }
        guard phase == .appearing else { return }
        guard shouldAnimate else {
            phase = .finished
            return
        }
        // Layout task replacement must not cancel or restart the sequence. The view cancels it on disappearance.
        let task = Task { @MainActor in
            defer { phase = .finished }
            do {
                try await sleep(.milliseconds(80))
                try Task.checkCancellation()
                withAnimation(.spring(duration: Constants.closingDuration, bounce: 0.05)) {
                    phase = .closing
                }
                try await sleep(.seconds(Constants.closingDuration))
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: Constants.movementDuration)) {
                    phase = .revealing
                }
                try await sleep(.seconds(Constants.movementDuration))
            } catch {
                return
            }
        }
        animationTask = task
        await task.value
    }

    func cancel() {
        animationTask?.cancel()
        phase = .finished
    }

    private enum Constants {
        static let closingDuration: TimeInterval = 0.2
        static let movementDuration: TimeInterval = 0.22
    }
}
