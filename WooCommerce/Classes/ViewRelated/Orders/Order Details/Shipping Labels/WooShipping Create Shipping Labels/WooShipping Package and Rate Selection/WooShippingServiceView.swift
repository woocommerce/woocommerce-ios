import SwiftUI

struct WooShippingServiceView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.shippingService)
                    .headlineStyle()
                Spacer()
            }
            WooShippingServiceCardView(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                                       title: "USPS - Media Mail",
                                       rate: "$7.63",
                                       daysToDelivery: "7 business days",
                                       extraInfo: "Includes tracking, insurance (up to $100.00), free pickup",
                                       trackingLabel: "Tracking",
                                       insuranceLabel: "Insurance (up to $100.00)",
                                       freePickupLabel: "Free pickup",
                                       signatureRequiredLabel: "Signature Required (+$3.70)",
                                       adultSignatureRequiredLabel: "Adult Signature Required (+$9.35)")
        }
    }
}

private extension WooShippingServiceView {
    enum Localization {
        static let shippingService = NSLocalizedString("wooShipping.createLabels.rates.shippingService",
                                                       value: "Shipping service",
                                                       comment: "Heading for the shipping service section in the shipping label creation screen.")
    }
}

#Preview {
    WooShippingServiceView()
}
