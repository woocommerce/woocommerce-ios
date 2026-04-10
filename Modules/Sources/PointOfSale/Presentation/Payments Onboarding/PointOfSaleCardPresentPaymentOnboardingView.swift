import SwiftUI

/// Displays the WooPayments onboarding UI based on the state.
struct PointOfSaleCardPresentPaymentOnboardingView: View {
    @ObservedObject var viewModel: PointOfSaleCardPresentPaymentOnboardingViewModel

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            AnyView(viewModel.onboardingViewContainer.view)
                // Hides the navigation bar title `navigationTitle` in `CardPresentPaymentsOnboardingView`.
                .toolbar(.hidden)
        }
        .posModalCloseButton(action: viewModel.cancelOnboarding,
                             accessibilityLabel: Localization.cancelOnboarding)
        .safariSheet(url: $viewModel.onboardingURL)
        .posModalSizing()
    }
}

private extension PointOfSaleCardPresentPaymentOnboardingView {
    enum Constants {
        static let verticalSpacing: CGFloat = POSSpacing.large
    }

    enum Localization {
        static let cancelOnboarding = NSLocalizedString(
            "pointOfSaleDashboard.payments.onboarding.cancel",
            value: "Cancel",
            comment: "Button to dismiss the payments onboarding sheet from the POS dashboard."
        )
    }
}


#if DEBUG

import enum Yosemite.CardPresentPaymentOnboardingState

final class PreviewOnboardingViewContainerConfiguration: CardPresentPaymentsOnboardingViewConfiguration {
    var showSupport: (() -> Void)?
    var showURL: ((URL) -> Void)?
    var state: CardPresentPaymentOnboardingState = .loading
}

#Preview {
    PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
        onboardingViewContainer: .init(configuration: PreviewOnboardingViewContainerConfiguration()), onDismissTap: nil)
    )
}
#endif
