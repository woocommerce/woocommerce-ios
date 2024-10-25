import Foundation

enum CardPresentPaymentOnboardingPresentationEvent {
    case showOnboarding(viewModel: CardPresentPaymentsOnboardingViewModel, onCancel: () -> Void)
    case onboardingComplete
}
