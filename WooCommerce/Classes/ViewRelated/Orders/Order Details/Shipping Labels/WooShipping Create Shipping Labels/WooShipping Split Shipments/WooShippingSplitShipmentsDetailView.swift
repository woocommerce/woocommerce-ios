import SwiftUI
import Yosemite

struct WooShippingSplitShipmentsDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: WooShippingSplitShipmentsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(viewModel.itemsCountLabel)
                            .headlineStyle()
                        Spacer()
                        Text(viewModel.itemsDetailLabel)
                            .foregroundStyle(Color(.textSubtle))
                    }

                    VStack(spacing: Layout.verticalSpacing) {
                        ForEach(viewModel.shipmentCardViewModels) { item in
                            CollapsibleShipmentCard(viewModel: item)
                        }
                    }
                }
                .padding(Layout.contentPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.selectAll) {
                        viewModel.selectAll()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension WooShippingSplitShipmentsDetailView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let verticalSpacing: CGFloat = 8
    }
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.title",
            value: "Split Shipments",
            comment: "Title of the split shipments detail view in the shipping label creation flow"
        )
        static let selectAll = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.selectAll",
            value: "Select All",
            comment: "Button to select all items in the shipment detail in the shipping label creation flow"
        )
        static let done = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.done",
            value: "Done",
            comment: "Button to save split shipment configurations in the shipping label creation flow"
        )
    }
}

#if DEBUG
#Preview {
    WooShippingSplitShipmentsDetailView(viewModel: WooShippingSplitShipmentsViewModel(order: ShippingLabelSampleData.sampleOrder(),
                                                                                      config: ShippingLabelSampleData.sampleWooShippingConfig(),
                                                                                      items: [ShippingLabelPackageItem(productOrVariationID: 1,
                                                                                                                       name: "Shirt",
                                                                                                                       weight: 0.5,
                                                                                                                       quantity: 2,
                                                                                                                       value: 9.99,
                                                                                                                       dimensions: ProductDimensions(length: "",
                                                                                                                                                     width: "",
                                                                                                                                                     height: ""),
                                                                                                                       attributes: [],
                                                                                                                       imageURL: nil)]))
}
#endif
