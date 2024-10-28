import SwiftUI

/// Displays the WooPayments onboarding UI based on the state.
struct PointOfSaleCardPresentPaymentOnboardingView: View {
    @ObservedObject var viewModel: PointOfSaleCardPresentPaymentOnboardingViewModel

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            HStack {
                Spacer()
                Button {
                    viewModel.cancelOnboarding()
                } label: {
                    Image(systemName: "xmark")
                        .font(.posButtonSymbol)
                }
                .accessibilityLabel(Localization.cancelOnboarding)
                .foregroundColor(Color.posTertiaryText)
            }
            CardPresentPaymentsOnboardingView(viewModel: viewModel.onboardingViewModel)
                // Hides the navigation bar title `navigationTitle` in `CardPresentPaymentsOnboardingView`.
                .toolbar(.hidden)
        }
        .padding(Constants.padding)
        .safariSheet(url: $viewModel.onboardingURL)
    }
}

private extension PointOfSaleCardPresentPaymentOnboardingView {
    enum Constants {
        static let verticalSpacing: CGFloat = 20.0
        static let padding: CGFloat = 40.0
    }

    enum Localization {
        static let cancelOnboarding = NSLocalizedString(
            "pointOfSaleDashboard.payments.onboarding.cancel",
            value: "Cancel",
            comment: "Button to dismiss the payments onboarding sheet from the POS dashboard."
        )
    }
}

#Preview {
    PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(onboardingViewModel: .init(fixedState: .genericError), onDismissTap: nil))
}
