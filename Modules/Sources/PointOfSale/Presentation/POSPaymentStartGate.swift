import Observation

/// Double-tap gate for the checkout payment buttons.
///
/// The gate closes when the merchant picks a payment method and opens again once that start is under way
/// or has ended. A start can end without changing any payment state, so the gate also opens when the start
/// returns: otherwise the buttons would stay disabled until the merchant leaves checkout.
@MainActor
@Observable
final class POSPaymentStartGate {
    private(set) var isStarting = false
    @ObservationIgnored private var attempt = 0

    /// Runs `start` unless another start holds the gate.
    /// - Parameter isStillPending: reads `@Observable` state. While it is `true` after `start` returned, the gate
    ///   stays closed for work the start left running, e.g. a reader connection.
    @discardableResult
    func run(_ start: @escaping @MainActor () async -> Void,
             isStillPending: @escaping @MainActor () -> Bool) -> Task<Void, Never>? {
        guard !isStarting else {
            return nil
        }
        isStarting = true
        attempt += 1
        let attempt = attempt
        return Task { @MainActor in
            await start()
            // The pending work can end before SwiftUI renders it as pending, so a view `onChange` could miss it.
            while attempt == self.attempt, isStarting, await Self.isPendingUntilNextChange(isStillPending) {
            }
            // An earlier start can return after the gate closed again for a newer one.
            guard attempt == self.attempt else {
                return
            }
            isStarting = false
        }
    }

    /// Returns `false` at once when nothing is pending, otherwise `true` after the observed state changed.
    /// The value that decides whether to wait is the one read under observation, so no change can be missed.
    private static func isPendingUntilNextChange(_ isStillPending: @escaping @MainActor () -> Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            let waiter = Waiter(continuation: continuation)
            let isPending = withObservationTracking {
                isStillPending()
            } onChange: {
                // `onChange` runs before the new value is set.
                Task { @MainActor in
                    waiter.resume(returning: true)
                }
            }
            if !isPending {
                waiter.resume(returning: false)
            }
        }
    }

    /// The observation callback can still fire after the wait ended because nothing was pending.
    @MainActor
    private final class Waiter {
        private var continuation: CheckedContinuation<Bool, Never>?

        init(continuation: CheckedContinuation<Bool, Never>) {
            self.continuation = continuation
        }

        func resume(returning isPending: Bool) {
            continuation?.resume(returning: isPending)
            continuation = nil
        }
    }

    func release(isStillPending: Bool) {
        guard !isStillPending else {
            return
        }
        isStarting = false
    }
}
