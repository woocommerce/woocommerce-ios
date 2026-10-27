import os
import Yosemite

/// In-Memory cache for the CardPresentPaymentOnboardingState
///
final class CardPresentPaymentOnboardingStateCache: Sendable {
    private let state = OSAllocatedUnfairLock<CardPresentPaymentOnboardingState?>(initialState: nil)

    var value: CardPresentPaymentOnboardingState? {
        state.withLock { $0 }
    }

    static let shared = CardPresentPaymentOnboardingStateCache()

    func update(_ newState: CardPresentPaymentOnboardingState) {
        state.withLock { $0 = newState }
    }

    func invalidate() {
        state.withLock { $0 = nil }
    }
}
