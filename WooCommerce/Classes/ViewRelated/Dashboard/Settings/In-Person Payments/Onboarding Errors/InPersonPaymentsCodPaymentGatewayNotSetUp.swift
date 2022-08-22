import SwiftUI

struct InPersonPaymentsCodPaymentGatewayNotSetUp: View {
    let viewModel: InPersonPaymentsCodPaymentGatewayNotSetUpViewModel

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: Localization.title,
                message: Localization.message,
                image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                    image: .waitingForCustomersImage,
                    height: Constants.imageHeight
                ),
                supportLink: true
            )

            Spacer()

            Button(Localization.skipButton, action: viewModel.skipTapped)
                .buttonStyle(SecondaryButtonStyle())

            Button(Localization.enableButton, action: {})
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: false))

            Spacer()

            InPersonPaymentsLearnMore(url: Constants.cashOnDeliveryLearnMoreUrl,
                                      formatText: Localization.cashOnDeliveryLearnMore)
        }
    }
}

struct InPersonPaymentsCodPaymentGatewayNotSetUp_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = InPersonPaymentsCodPaymentGatewayNotSetUpViewModel(completion: {})
        return InPersonPaymentsCodPaymentGatewayNotSetUp(viewModel: viewModel)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Add Pay in Person to your checkout",
        comment: "Title for the card present payments onboarding step encouraging the merchant to enable the " +
        "Pay in Person payment gateway.")

    static let message = NSLocalizedString(
        "A \"Pay in Person\" option on your checkout lets you accept card or cash payments on collection or delivery.",
        comment: "The message explaining what will happen when the merchant enables the Pay in Person payment " +
        "gateway during card present payments onboarding.")

    static let skipButton = NSLocalizedString(
        "Skip for now",
        comment: "Title for the button to skip the onboarding step encoraging the merchant to enable the" +
        "Pay in Person payment gateway")

    static let enableButton = NSLocalizedString(
        "Enable Pay in Person",
        comment: "Title for the button to enable the Pay in Person payment gateway during card present " +
        "payments onboarding.")

    static let cashOnDeliveryLearnMore = NSLocalizedString(
        "%1$@ about adding Pay in Person to your checkout",
        comment: "A label prompting users to learn more about card readers. %1$@ is a placeholder that is " +
        "always replaced with \"Learn more\" string, which should be translated separately and considered " +
        "part of this sentence.")
}

private enum Constants {
    static let imageHeight: CGFloat = 140.0
    static let cashOnDeliveryLearnMoreUrl = URL(
        string: "https://woocommerce.com/document/stripe/accept-in-person-payments-with-stripe/#section-8")!
}
