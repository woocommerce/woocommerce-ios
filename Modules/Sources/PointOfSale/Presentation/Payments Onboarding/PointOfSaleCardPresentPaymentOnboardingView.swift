import SwiftUI

/// Displays the WooPayments onboarding UI based on the state.
struct PointOfSaleCardPresentPaymentOnboardingView: View {
    @Environment(\.posMetrics) private var metrics
    @ObservedObject var viewModel: PointOfSaleCardPresentPaymentOnboardingViewModel

    var body: some View {
        VStack(spacing: metrics.spacing.large) {
            AnyView(viewModel.onboardingViewContainer.view)
                // Hides the navigation bar title `navigationTitle` in `CardPresentPaymentsOnboardingView`.
                .toolbar(.hidden)
        }
        .posModalCloseButton(action: viewModel.cancelOnboarding,
                             accessibilityLabel: Localization.cancelOnboarding)
        .safariSheet(url: $viewModel.onboardingURL)
        .posModalSizing(fullScreenWhenCompact: true)
    }
}

extension POSModalCompactStyle {
    static var cardPaymentsOnboarding: POSModalCompactStyle {
        .fullScreen(title: NSLocalizedString(
            "pos.cardPaymentsOnboarding.modal.title",
            value: "Card payments",
            comment: "Title in the header of the full-screen card payments onboarding flow on phone."
        ))
    }
}

private extension PointOfSaleCardPresentPaymentOnboardingView {
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
    .posPreviewModalParentSize()
}
#endif
