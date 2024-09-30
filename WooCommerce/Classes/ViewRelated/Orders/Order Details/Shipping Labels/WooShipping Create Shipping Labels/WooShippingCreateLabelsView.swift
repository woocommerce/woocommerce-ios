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
                            Toggle(Localization.BottomSheet.markComplete, isOn: .constant(false)) // TODO: 14044 - Handle this toggle setting
                                .font(.subheadline)

                            Button {
                                // TODO: 13556 - Trigger purchase action
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
                        Text(Localization.BottomSheet.orderDetails)
                            .footnoteStyle()

                        Grid(alignment: .leading, verticalSpacing: .zero) {
                            GridRow(alignment: .top) {
                                Text(Localization.BottomSheet.shipFrom)
                                Text("417 MONTGOMERY ST, SAN FRANCISCO") // TODO: 14044 - Show real "ship from" address (store address)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding()
                            Divider()
                            GridRow(alignment: .top) {
                                Text(Localization.BottomSheet.shipTo)
                                VStack(alignment: .leading) {
                                    Text("1 Infinite Loop") // TODO: 14044 - Show real "ship to" address (customer address)
                                        .bold()
                                    Text("Cupertino, CA 95014")
                                    Text("USA")
                                }
                            }
                            .padding()
                        }
                        .font(.subheadline)
                        .roundedBorder(cornerRadius: Layout.cornerRadius, lineColor: Color(.separator), lineWidth: 0.5)
                        Group {
                            AdaptiveStack {
                                Image(uiImage: .productIcon)
                                    .frame(width: Layout.iconSize)
                                Text(viewModel.items.itemsCountLabel)
                                    .bold()
                                Spacer()
                                Text("$148.50") // TODO: 14044 - Show real item total
                            }
                            AdaptiveStack {
                                Image(uiImage: .shippingIcon)
                                    .frame(width: Layout.iconSize)
                                Text("Flat rate shipping") // TODO: 14044 - Show real shipping name
                                    .bold()
                                Spacer()
                                Text("$25.00") // TODO: 14044 - Show real shipping amount
                            }
                        }

                        Divider()
                            .padding(.trailing, -16)
                        Text(Localization.BottomSheet.shipmentCosts)
                            .footnoteStyle()
                        Group {
                            AdaptiveStack {
                                Text(Localization.BottomSheet.subtotal)
                                Spacer()
                                Text("$0.00") // TODO: 13555 - Show real subtotal value
                                    .if(true) { subtotal in // TODO: 14044 - Only show placeholder if subtotal is not available
                                        subtotal.redacted(reason: .placeholder)
                                    }
                            }
                            AdaptiveStack {
                                Text(Localization.BottomSheet.total)
                                    .bold()
                                Spacer()
                                Text("$0.00") // TODO: 13555 - Show real total value
                                    .if(true) { total in // TODO: 14044 - Only show placeholder if total is not available
                                        total.redacted(reason: .placeholder)
                                    }
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
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 32
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
