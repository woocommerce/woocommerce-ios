import SwiftUI

struct InPersonPaymentsCodPaymentGatewayNotSetUp: View {
    var body: some View {
        VStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: Localization.title,
                message: Localization.message,
                image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                    image: .paymentErrorImage,
                    height: 180.0
                ),
                supportLink: true
            )

            Spacer()

            Button(Localization.skipButton, action: {})
                .buttonStyle(SecondaryButtonStyle())

            Button(Localization.enableButton, action: {})
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: false))

            Spacer()

            InPersonPaymentsLearnMore()
        }.padding()
    }
}

struct InPersonPaymentsCodPaymentGatewayNotSetUp_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsCodPaymentGatewayNotSetUp()
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Add Pay in Person to your checkout",
        comment: "Title for the card present payments onboarding step encouraging the merchant to enable the " +
        "Pay in Person payment gateway.")

    static let message = NSLocalizedString(
        "A \"Pay in Person\" option on your checkout lets you accept card or cash payments on collection or delivery",
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
}
