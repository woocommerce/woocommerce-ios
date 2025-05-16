import SwiftUI
import Yosemite

struct WooShippingSplitShipmentsRow: View {
    var onShowingSplitShipments: () -> Void

    var body: some View {
        AdaptiveStack {
            Text(Localization.products)
                .tertiaryTitleStyle()
            Spacer()
            Button(Localization.splitShipments) {
                onShowingSplitShipments()
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.vertical, Layout.verticalPadding)
    }
}

private extension WooShippingSplitShipmentsRow {
    enum Layout {
        static let verticalPadding: CGFloat = 16
    }

    enum Localization {
        static let products = NSLocalizedString("wooShipping.splitShipments.products",
                                                value: "Products",
                                                comment: "Label for section in shipping label creation to split shipments.")

        static let splitShipments = NSLocalizedString("wooShipping.splitShipments.splitShipmentsButtonTitle",
                                                      value: "Split shipments",
                                                      comment: "Title for button in shipping label creation to start split shipments flow.")
    }
}

#if DEBUG
#Preview {
    WooShippingSplitShipmentsRow(onShowingSplitShipments: {})
        .padding()
}
#endif
