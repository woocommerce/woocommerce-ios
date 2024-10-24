import Foundation

enum CardPresentPaymentEvent {
    case idle
    case show(eventDetails: CardPresentPaymentEventDetails)
    case showOnboarding(onboardingViewModel: CardPresentPaymentsOnboardingViewModel, onCancel: () -> Void)
}
