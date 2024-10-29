import SwiftUI

struct WooShippingPostPurchaseView: View {
    var body: some View {
        Text(Localization.readyToPrint)
            .headlineStyle()
    }
}

private extension WooShippingPostPurchaseView {
    enum Localization {
        static let readyToPrint = NSLocalizedString("wooShipping.createLabels.postPurchase.readyToPrint",
                                                    value: "Your shipping label is ready to print",
                                                    comment: "Message displayed on the shipping label screen when a purchased shipping label can be printed")
    }
}

#Preview {
    WooShippingPostPurchaseView()
}
