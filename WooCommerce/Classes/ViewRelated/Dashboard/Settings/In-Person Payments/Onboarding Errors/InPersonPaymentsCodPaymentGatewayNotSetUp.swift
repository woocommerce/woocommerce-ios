import SwiftUI

struct InPersonPaymentsCodPaymentGatewayNotSetUp: View {
    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true
        )
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
}
