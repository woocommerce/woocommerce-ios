import Foundation

enum CardPresentPaymentEvent {
    case idle
    case show(eventDetails: CardPresentPaymentEventDetails)
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
