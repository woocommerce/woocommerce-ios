import Yosemite

/// In-Memory cache for the CardPresentPaymentOnboardingState
/// 
class CardPresentPaymentOnboardingStateCache {
    private(set) var value: CardPresentPaymentOnboardingState?

    static let shared: CardPresentPaymentOnboardingStateCache = CardPresentPaymentOnboardingStateCache()

    func update(_ newState: CardPresentPaymentOnboardingState) {
        value = newState
    }

    func invalidate() {
        value = nil
    }
}
