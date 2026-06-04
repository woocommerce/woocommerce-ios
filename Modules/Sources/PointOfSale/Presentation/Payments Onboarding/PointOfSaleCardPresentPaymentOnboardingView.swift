import SwiftUI

/// Displays the WooPayments onboarding UI based on the state.
struct PointOfSaleCardPresentPaymentOnboardingView: View {
    @ObservedObject var viewModel: PointOfSaleCardPresentPaymentOnboardingViewModel
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        if isPOSPhoneLayout {
            content
                .padding(PointOfSaleReaderConnectionModalLayout.contentPadding)
                .frame(width: parentSize.width, height: parentSize.height)
        } else {
            content
                .posModalSizing()
        }
    }

    private var content: some View {
        VStack(spacing: Constants.verticalSpacing) {
            AnyView(viewModel.onboardingViewContainer.view)
                // Hides the navigation bar title `navigationTitle` in `CardPresentPaymentsOnboardingView`.
                .toolbar(.hidden)
        }
        .posModalCloseButton(action: viewModel.cancelOnboarding,
                             accessibilityLabel: Localization.cancelOnboarding)
        .safariSheet(url: $viewModel.onboardingURL)
    }

    private var isPOSPhoneLayout: Bool {
        layoutScale == .phone && UIDevice.current.userInterfaceIdiom == .phone
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
