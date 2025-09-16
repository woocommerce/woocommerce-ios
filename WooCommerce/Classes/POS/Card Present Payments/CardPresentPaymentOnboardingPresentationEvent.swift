import Foundation

enum CardPresentPaymentOnboardingPresentationEvent {
    case showOnboarding(factory: CardPresentPaymentOnboardingViewFactory, onCancel: () -> Void)
    case onboardingComplete
}
