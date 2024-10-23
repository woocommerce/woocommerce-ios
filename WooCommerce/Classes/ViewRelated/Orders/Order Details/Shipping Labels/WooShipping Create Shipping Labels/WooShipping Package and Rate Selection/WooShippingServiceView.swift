import SwiftUI

struct WooShippingServiceView: View {
    @ObservedObject var viewModel: WooShippingServiceViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.shippingService)
                    .headlineStyle()
                Spacer()
            }
            VStack {
                ForEach(viewModel.rates) { rate in
                    WooShippingServiceCardView(viewModel: rate)
                }
            }
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
    WooShippingServiceView(viewModel: .init())
}
