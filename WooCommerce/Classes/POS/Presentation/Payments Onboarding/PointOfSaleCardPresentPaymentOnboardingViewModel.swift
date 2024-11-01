import Foundation
import protocol WooFoundation.Analytics

final class PointOfSaleCardPresentPaymentOnboardingViewModel: ObservableObject {
    let onboardingViewModel: CardPresentPaymentsOnboardingViewModel
    @Published var onboardingURL: URL?

    private let onDismissTap: (() -> Void)?
    private let analytics: Analytics

    init(onboardingViewModel: CardPresentPaymentsOnboardingViewModel,
         onDismissTap: (() -> Void)?,
         analytics: Analytics = ServiceLocator.analytics) {
        self.onboardingViewModel = onboardingViewModel
        self.onDismissTap = onDismissTap
        self.analytics = analytics
        onboardingViewModel.showURL = { [weak self] url in
            self?.onboardingURL = url
        }
    }

    /// Called when the user taps to dismiss the onboarding UI.
    func cancelOnboarding() {
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewModel.state))
        onDismissTap?()
    }

    /// Tracks when the view appears.
    func trackOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }
}
