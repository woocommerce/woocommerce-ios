import Foundation

enum CardPresentPaymentOnboardingPresentationEvent {
    case showOnboarding(factory: CardPresentPaymentOnboardingViewContainer, onCancel: () -> Void)
    case onboardingComplete
}
