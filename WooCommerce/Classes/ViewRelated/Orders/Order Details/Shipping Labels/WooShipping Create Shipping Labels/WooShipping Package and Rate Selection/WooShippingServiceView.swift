import SwiftUI

struct WooShippingServiceView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.shippingService)
                    .headlineStyle()
                Spacer()
            }
            WooShippingServiceCardView(viewModel: WooShippingServiceCardViewModel(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                                                                                  title: "USPS - Media Mail",
                                                                                  rateLabel: "$7.63",
                                                                                  daysToDeliveryLabel: "7 business days",
                                                                                  extraInfoLabel: "Includes tracking, insurance (up to $100.00), free pickup",
                                                                                  hasTracking: true,
                                                                                  insuranceLabel: "Insurance (up to $100.00)",
                                                                                  hasFreePickup: true,
                                                                                  signatureRequiredLabel: "Signature Required (+$3.70)",
                                                                                  adultSignatureRequiredLabel: "Adult Signature Required (+$9.35)"))
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
