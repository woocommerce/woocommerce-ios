import SwiftUI

/// Hosting controller for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewHostingController: UIHostingController<WooShippingCreateLabelsView> {
    let viewModel: WooShippingCreateLabelsViewModel

    init(viewModel: WooShippingCreateLabelsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WooShippingCreateLabelsView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to create shipping labels with the Woo Shipping extension.
///
struct WooShippingCreateLabelsView: View {
    @ObservedObject var viewModel: WooShippingCreateLabelsViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isiPhonePortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }

    /// Tracks the size of the "Ship from" label in the Shipment Details address section.
    @State private var shipmentDetailsShipFromSize: CGSize = .zero

    /// Whether the shipment details bottom sheet is expanded.
    @State private var isShipmentDetailsExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.verticalSpacing) {
                    WooShippingItems(viewModel: viewModel.items)

                    WooShippingHazmat()

                    WooShippingPackageAndRatePlaceholder()
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                ExpandableBottomSheet(onChangeOfExpansion: { isExpanded in
                    isShipmentDetailsExpanded = isExpanded
                }) {
                    if isShipmentDetailsExpanded {
                        CollapsibleHStack(spacing: Layout.bottomSheetSpacing) {
                            Toggle(Localization.BottomSheet.markComplete, isOn: $viewModel.markOrderComplete)
                                .font(.subheadline)

                            Button {
                                viewModel.purchaseLabel()
                            } label: {
                                Text(Localization.BottomSheet.purchase)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(true) // TODO: 14044 - Enable button when shipping label is ready to purchase
                        }
                        .padding(.horizontal, Layout.bottomSheetPadding)
                    } else {
                        Text(Localization.BottomSheet.shipmentDetails)
                            .foregroundStyle(Color(.primary))
                            .bold()
                    }
                } expandableContent: {
                    VStack(alignment: .leading, spacing: Layout.bottomSheetSpacing) {
                        if isiPhonePortrait {
                            Text(Localization.BottomSheet.orderDetails)
                                .footnoteStyle()
                        }
                        CollapsibleHStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: .zero) {
                            HStack(alignment: .firstTextBaseline, spacing: Layout.bottomSheetSpacing) {
                                Text(Localization.BottomSheet.shipFrom)
                                    .trackSize(size: $shipmentDetailsShipFromSize)
                                Text(viewModel.originAddress)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(Layout.bottomSheetPadding)
                            Divider()
                            HStack(alignment: .firstTextBaseline, spacing: Layout.bottomSheetSpacing) {
                                Text(Localization.BottomSheet.shipTo)
                                    .frame(width: shipmentDetailsShipFromSize.width, alignment: .leading)
                                VStack(alignment: .leading) {
                                    ForEach(viewModel.destinationAddressLines, id: \.self) { addressLine in
                                        Text(addressLine)
                                            .if(addressLine == viewModel.destinationAddressLines.first) { line in
                                                line.bold()
                                            }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(Layout.bottomSheetPadding)
                        }
                        .font(.subheadline)
                        .roundedBorder(cornerRadius: Layout.cornerRadius, lineColor: Color(.separator), lineWidth: 0.5)

                        // Always use a VStack in iPhone portrait orientation.
                        // CollapsibleHStack will use an HStack even if some text is truncated.
                        if isiPhonePortrait {
                            VStack(spacing: Layout.bottomSheetPadding) {
                                orderDetails
                                Divider()
                                    .padding(.trailing, Layout.bottomSheetPadding * -1)
                                shipmentDetails
                            }
                        } else {
                            HStack(spacing: Layout.bottomSheetPadding) {
                                orderDetails
                                Divider()
                                    .padding(.trailing, Layout.bottomSheetPadding * -1)
                                shipmentDetails
                            }
                        }
                    }
                    .padding([.bottom, .horizontal], Layout.bottomSheetPadding)
                }
                .ignoresSafeArea(edges: .horizontal)
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension WooShippingCreateLabelsView {
    /// View showing the order details, such as order items and shipping costs.
    var orderDetails: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            if !(isiPhonePortrait) {
                Text(Localization.BottomSheet.orderDetails)
                    .footnoteStyle()
            }
            AdaptiveStack {
                Image(uiImage: .productIcon)
                    .frame(width: Layout.iconSize)
                Text(viewModel.items.itemsCountLabel)
                    .bold()
                Spacer()
                Text("$148.50") // TODO: 14044 - Show real item total
            }
            .frame(idealHeight: Layout.rowHeight)
            AdaptiveStack {
                Image(uiImage: .shippingIcon)
                    .frame(width: Layout.iconSize)
                Text("Flat rate shipping") // TODO: 14044 - Show real shipping name
                    .bold()
                    .lineLimit(nil)
                Spacer()
                Text("$25.00") // TODO: 14044 - Show real shipping amount
            }
            .frame(idealHeight: Layout.rowHeight)
        }
    }

    /// View showing the shipment details, such as shipping rate and additional costs.
    var shipmentDetails: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text(Localization.BottomSheet.shipmentCosts)
                .footnoteStyle()
            AdaptiveStack {
                Text(Localization.BottomSheet.subtotal)
                Spacer()
                Text("$0.00") // TODO: 13555 - Show real subtotal value
                    .if(true) { subtotal in // TODO: 14044 - Only show placeholder if subtotal is not available
                        subtotal.redacted(reason: .placeholder)
                    }
            }
            .frame(idealHeight: Layout.rowHeight)
            AdaptiveStack {
                Text(Localization.BottomSheet.total)
                    .bold()
                Spacer()
                Text("$0.00") // TODO: 13555 - Show real total value
                    .if(true) { total in // TODO: 14044 - Only show placeholder if total is not available
                        total.redacted(reason: .placeholder)
                    }
            }
            .frame(idealHeight: Layout.rowHeight)
        }
    }
}

private extension WooShippingCreateLabelsView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 32
        static let rowHeight: CGFloat = 32
        static let chevronSize: CGFloat = 30
        static let bottomSheetSpacing: CGFloat = 16
        static let bottomSheetPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString("wooShipping.createLabels.title",
                                             value: "Create Shipping Labels",
                                             comment: "Title for the screen to create a shipping label")
        static let cancel = NSLocalizedString("wooShipping.createLabel.cancelButton",
                                              value: "Cancel",
                                              comment: "Title of the button to dismiss the shipping label creation screen")

        enum BottomSheet {
            static let shipmentDetails = NSLocalizedString("wooShipping.createLabels.bottomSheet.title",
                                                           value: "Shipment details",
                                                           comment: "Label on the bottom sheet that can be expanded to show shipment details"
                                                           + "on the shipping label creation screen")
            static let orderDetails = NSLocalizedString("wooShipping.createLabels.bottomSheet.orderDetails",
                                                        value: "Order details",
                                                        comment: "Header for order details section on the shipping label creation screen")
                .localizedUppercase
            static let shipFrom = NSLocalizedString("wooShipping.createLabels.bottomSheet.shipFrom",
                                                    value: "Ship from",
                                                    comment: "Label for address where the shipment is shipped from on the shipping label creation screen")
            static let shipTo = NSLocalizedString("wooShipping.createLabels.bottomSheet.shipTo",
                                                    value: "Ship to",
                                                    comment: "Label for address where the shipment is shipped to on the shipping label creation screen")
            static let shipmentCosts = NSLocalizedString("wooShipping.createLabels.bottomSheet.shipmentCosts",
                                                        value: "Shipment costs",
                                                        comment: "Header for shipment costs section on the shipping label creation screen")
                .localizedUppercase
            static let subtotal = NSLocalizedString("wooShipping.createLabels.bottomSheet.subtotal",
                                                        value: "Subtotal",
                                                        comment: "Label for row showing the subtotal for shipment costs on the shipping label creation screen")
            static let total = NSLocalizedString("wooShipping.createLabels.bottomSheet.total",
                                                        value: "Total",
                                                        comment: "Label for row showing the total for shipment costs on the shipping label creation screen")
            static let markComplete = NSLocalizedString("wooShipping.createLabels.bottomSheet.markComplete",
                                                        value: "Mark this order complete and notify the customer",
                                                        comment: "Label for the toggle to mark the order as complete on the shipping label creation screen")
            static let paperSize = NSLocalizedString("wooShipping.createLabels.bottomSheet.paperSize",
                                                     value: "Choose label paper size",
                                                     comment: "Label for the menu to select a paper size on the shipping label creation screen")
            static let purchase = NSLocalizedString("wooShipping.createLabels.bottomSheet.purchase",
                                                    value: "Purchase Label",
                                                    comment: "Label for button to purchase the shipping label on the shipping label creation screen")
        }
    }
}
