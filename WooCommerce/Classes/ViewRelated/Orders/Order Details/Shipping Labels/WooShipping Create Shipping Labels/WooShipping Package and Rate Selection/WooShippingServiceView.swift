import SwiftUI

struct WooShippingServiceView: View {
    var body: some View {
        Text(Localization.shippingService)
            .headlineStyle()
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
