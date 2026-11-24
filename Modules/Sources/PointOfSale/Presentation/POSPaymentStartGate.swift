import Foundation
import Observation

/// Blocks duplicate payment starts until the Checkout action or pending reader work finishes.
@MainActor
@Observable
final class POSPaymentStartGate {
    private var attempt: UUID?

    func isClosed(isCardStartPending: Bool) -> Bool {
        attempt != nil || isCardStartPending
    }

    @discardableResult
    func run(_ start: @escaping @MainActor () async -> Void,
             isCardStartPending: Bool) -> Task<Void, Never>? {
        guard !isClosed(isCardStartPending: isCardStartPending) else { return nil }
        let attempt = UUID()
        self.attempt = attempt
        return Task { @MainActor in
            await start()
            // An earlier action can return while a later action holds the gate.
            if self.attempt == attempt {
                self.attempt = nil
            }
        }
    }

    func release(isStillPending: Bool) {
        if !isStillPending {
            attempt = nil
        }
    }
}
