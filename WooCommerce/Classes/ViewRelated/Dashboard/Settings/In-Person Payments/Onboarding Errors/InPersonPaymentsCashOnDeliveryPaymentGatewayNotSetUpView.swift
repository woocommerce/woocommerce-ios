import SwiftUI
import Yosemite

struct InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpView: View {
    @ObservedObject var viewModel: InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: Localization.title,
                message: Localization.message,
                secondaryMessage: Localization.secondaryMessage,
                image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                    image: .puzzleExtensionsImage,
                    height: Constants.imageHeight
                ),
                supportLink: true
            )

            Spacer()

            Button(Localization.skipButton, action: viewModel.skipTapped)
                .buttonStyle(SecondaryButtonStyle())

            Button(Localization.enableButton, action: viewModel.enableTapped)
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.awaitingResponse))

            Spacer()

            InPersonPaymentsLearnMore(
                viewModel: LearnMoreViewModel(
                    url: viewModel.learnMoreURL,
                    formatText: Localization.cashOnDeliveryLearnMore,
                    tappedAnalyticEvent: viewModel.learnMoreEvent))
            .padding(.vertical, Constants.learnMorePadding)
        }
    }
}

struct InPersonPaymentsCodPaymentGatewayNotSetUp_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
            configuration: CardPresentPaymentsConfiguration(country: .US),
            plugin: .wcPay,
            analyticReason: "",
            completion: {})
        return InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpView(viewModel: viewModel)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Do you want to add Pay in Person to your web checkout?",
        comment: "Title for the card present payments onboarding step encouraging the merchant to enable the " +
        "Pay in Person payment gateway.")

    static let message = NSLocalizedString(
        "Enabling \"Pay in Person\" lets customers pay you for online orders at delivery via cash or card.",
        comment: "The message explaining what will happen when the merchant enables the Pay in Person payment " +
        "gateway during card present payments onboarding.")

    static let secondaryMessage = NSLocalizedString(
        "Orders can still be created manually without enabling this feature.",
        comment: "Additional message explaining what will happen when the merchant enables the Pay in Person payment " +
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
        "%1$@ about accepting payments with your mobile device and ordering card readers.",
        comment: "A label prompting users to learn more about card readers. %1$@ is a placeholder that is " +
        "always replaced with \"Learn more\" string, which should be translated separately and considered " +
        "part of this sentence.")
}

private enum Constants {
    static let imageHeight: CGFloat = 88.0
    static let learnMorePadding: CGFloat = 8
}
