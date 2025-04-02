import SwiftUI
import Yosemite

struct WooShippingSplitShipmentsRow: View {
    @State private var isShowingDetailView = false

    let viewModel: WooShippingSplitShipmentsViewModel

    init(viewModel: WooShippingSplitShipmentsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AdaptiveStack {
            Text(Localization.products)
                .tertiaryTitleStyle()
            Spacer()
            Button(Localization.splitShipments) {
                isShowingDetailView = true
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.vertical, Layout.verticalPadding)
        .fullScreenCover(isPresented: $isShowingDetailView) {
            WooShippingSplitShipmentsDetailView(viewModel: viewModel)
        }
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
    WooShippingSplitShipmentsRow(viewModel: WooShippingSplitShipmentsViewModel(
        order: ShippingLabelSampleData.sampleOrder(),
        shipments: [
            WooShippingSplitShipmentsViewModel.Shipment(contents: [ShippingLabelPackageItem(productOrVariationID: 1,
                                                                                            orderItemID: 12,
                                                                                            name: "Shirt",
                                                                                            weight: 0.5,
                                                                                            quantity: 2,
                                                                                            value: 9.99,
                                                                                            dimensions: ProductDimensions(length: "",
                                                                                                                          width: "",
                                                                                                                          height: ""),
                                                                                            attributes: [],
                                                                                            imageURL: nil)], currency: "$",
                                                        currencySettings: ServiceLocator.currencySettings,
                                                        shippingSettingsService: ServiceLocator.shippingSettingsService)
        ]))
    .padding()
}
#endif
