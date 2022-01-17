import SwiftUI

struct InPersonPaymentsSelectPlugin: View {
    let onRefresh: (Bool) -> Void

    @State private var activateWCPay = true
    @State private var activateStripe = true

    var body: some View {
        VStack {
            InPersonPaymentsOnboardingError(
                title: Localization.unavailable,
                message: Localization.message,
                image: InPersonPaymentsOnboardingError.ImageInfo(
                    image: .paymentErrorImage,
                    height: 180.0
                ),
                supportLink: false,
                learnMore: false,
                button: InPersonPaymentsOnboardingError.ButtonInfo(
                    text: Localization.primaryButton,
                    action: {
                        onRefresh(activateStripe)
                    }
                )
            )

            VStack {
                // Switch to activate WooCommercePayments
                Toggle(Localization.wcPay, isOn: $activateWCPay)
                    .onChange(of: activateWCPay, perform: { value in
                        activateStripe = !value
                    })

                // Switch to activate Stripe extension
                Toggle(Localization.stripeExtension, isOn: $activateStripe)
                    .onChange(of: activateStripe, perform: { value in
                        activateWCPay = !value
                    })
            }
            .padding([.leading, .trailing, .bottom])
        }
    }
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "Please select an extension",
        comment: "Title for the error screen when there is more than one extension active."
    )

    static let message = NSLocalizedString(
        "Choose between WooCommerce Payments and Stripe Extension",
        comment: "Message requesting merchants to select between available payments processors"
    )

    static let stripeExtension = NSLocalizedString(
        "Stripe Extension",
        comment: "Message asking merchants whether the Stripe Extension should be active"
    )

    static let wcPay = NSLocalizedString(
        "WooCommerce Payments",
        comment: "Message asking merchants whether the WooCommerce Payments should be active"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh",
        comment: "Button to reload plugin data after selecting a payment plugin"
    )
}

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPlugin(onRefresh: {_ in })
    }
}
