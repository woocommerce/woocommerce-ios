import Foundation

public enum CardPresentPaymentEvent {
    case idle
    case show(eventDetails: CardPresentPaymentEventDetails)
    case showOnboarding(factory: CardPresentPaymentOnboardingViewContainer, onCancel: () -> Void)
}
