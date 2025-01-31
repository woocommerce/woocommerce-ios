import Foundation

final class PointOfSaleCardPresentPaymentOnboardingViewModel: ObservableObject {
    let onboardingViewModel: CardPresentPaymentsOnboardingViewModel
    @Published var onboardingURL: URL?

    private let onDismissTap: (() -> Void)?

    init(onboardingViewModel: CardPresentPaymentsOnboardingViewModel,
         onDismissTap: (() -> Void)?) {
        self.onboardingViewModel = onboardingViewModel
        self.onDismissTap = onDismissTap
        onboardingViewModel.showURL = { [weak self] url in
            self?.onboardingURL = url
        }
    }

    /// Called when the user taps to dismiss the onboarding UI.
    func cancelOnboarding() {
        onDismissTap?()
    }
}
