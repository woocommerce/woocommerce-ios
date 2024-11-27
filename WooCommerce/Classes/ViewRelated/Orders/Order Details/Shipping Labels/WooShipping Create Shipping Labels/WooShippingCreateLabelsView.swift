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
                if let storeOptions = viewModel.storeOptions {
                    VStack(spacing: Layout.verticalSpacing) {
                        if viewModel.canViewLabel, let postPurchase = viewModel.postPurchase {
                            WooShippingPostPurchaseView(viewModel: postPurchase)
                        }

                        WooShippingItems(viewModel: viewModel.items)

                        WooShippingHazmat(enabled: !viewModel.canViewLabel)

                        if viewModel.canViewLabel {
                            EmptyView()
                        } else if let shippingService = viewModel.shippingService {
                            // TODO: Display package section
                            // Package heading and edit button
                            // Selected package details
                            // Total shipment weight field
                            WooShippingServiceView(viewModel: shippingService)
                                .padding(.horizontal, -16)
                        } else {
                            WooShippingPackageAndRatePlaceholder(storeOptions: storeOptions)
                        }
                    }
                    .padding(16)
                }
                else {
                    loadingView
                }
            }
            .safeAreaInset(edge: .bottom) {
                expandableBottomSheet
            }
            .navigationTitle(viewModel.canViewLabel ? Localization.viewLabelTitle : Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.canViewLabel ? Localization.close : Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear() {
            guard viewModel.storeOptions == nil else { return }
            viewModel.loadStoreOptions()
        }
    }

    @ViewBuilder
    private var expandableBottomSheet: some View {
        if viewModel.storeOptions == nil {
            EmptyView()
        }
        else {
            ExpandableBottomSheet(onChangeOfExpansion: { isExpanded in
                isShipmentDetailsExpanded = isExpanded
            }) {
                if isShipmentDetailsExpanded && !viewModel.canViewLabel {
                    CollapsibleHStack(spacing: Layout.bottomSheetSpacing) {
                        Toggle(Localization.BottomSheet.markComplete, isOn: $viewModel.markOrderComplete)
                            .font(.subheadline)
                        purchaseButton
                    }
                    .padding(.horizontal, Layout.bottomSheetPadding)
                } else {
                    VStack {
                        Text(Localization.BottomSheet.shipmentDetails)
                            .foregroundStyle(Color(.primary))
                            .bold()
                        if viewModel.selectedPackage != nil && !viewModel.canViewLabel {
                            purchaseButton
                        }
                    }
                    .padding(.horizontal, Layout.bottomSheetPadding)
                }
            } expandableContent: {
                expandableContent
            }
            .ignoresSafeArea(edges: .horizontal)
        }
    }

    private var expandableContent: some View {
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
                HStack(alignment: .top, spacing: Layout.bottomSheetPadding) {
                    orderDetails
                    Divider()
                        .padding(.trailing, Layout.bottomSheetPadding * -1)
                    shipmentDetails
                }
            }
        }
        .padding([.bottom, .horizontal], Layout.bottomSheetPadding)
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingStoreOptions {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            }
            else {
                Button {
                    viewModel.loadStoreOptions()
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                }
            }
            Spacer()
        }
        .padding()
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
                Text(viewModel.items.itemsPriceLabel)
            }
            .frame(idealHeight: Layout.rowHeight)
            ForEach(viewModel.shippingLines) { shippingLine in
                AdaptiveStack {
                    Image(uiImage: .shippingIcon)
                        .frame(width: Layout.iconSize)
                    Text(shippingLine.title)
                        .bold()
                        .lineLimit(nil)
                    Spacer()
                    Text(shippingLine.formattedTotal)
                }
                .frame(idealHeight: Layout.rowHeight)
            }
        }
    }

    /// View showing the shipment details, such as shipping rate and additional costs.
    var shipmentDetails: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text(Localization.BottomSheet.shipmentCosts)
                .footnoteStyle()
            Group {
                if viewModel.shippingRates.isNotEmpty {
                    ForEach(viewModel.shippingRates, id: \.title) { rate in
                        shippingRateRow(label: rate.title, amount: rate.amount)
                    }
                } else {
                    shippingRateRow(label: Localization.BottomSheet.subtotal, amount: nil)
                }
                shippingRateRow(label: Localization.BottomSheet.total, amount: viewModel.totalCost)
                    .bold()
            }
            .frame(idealHeight: Layout.rowHeight)
        }
    }

    func shippingRateRow(label: String, amount: String?) -> some View {
        AdaptiveStack {
            Text(label)
            Spacer()
            Text(amount ?? "$0.00")
                .if(amount == nil) { amount in
                    amount.redacted(reason: .placeholder)
                }
        }
    }

    /// View showing the shipping label purchase button.
    var purchaseButton: some View {
        Button {
            viewModel.purchaseLabel()
        } label: {
            Text(Localization.BottomSheet.purchaseLabel(with: viewModel.totalCost))
        }
        .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isPurchasingLabel))
        .disabled(!viewModel.isPurchaseButtonEnabled)
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
        static let viewLabelTitle = NSLocalizedString("wooShipping.createLabels.viewLabelTitle",
                                                      value: "View Shipping Label",
                                                      comment: "Title for the screen to view a shipping label")
        static let cancel = NSLocalizedString("wooShipping.createLabel.cancelButton",
                                              value: "Cancel",
                                              comment: "Title of the button to dismiss the shipping label creation screen")
        static let close = NSLocalizedString("wooShipping.createLabel.closeButton",
                                             value: "Close",
                                             comment: "Title of the button to dismiss the shipping label screen")

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
            static func purchaseLabel(with price: String?) -> String {
                guard let price else {
                    return purchase
                }
                return String.localizedStringWithFormat(purchaseFormat, price)
            }
            static let purchase = NSLocalizedString("wooShipping.createLabels.bottomSheet.purchase",
                                                    value: "Purchase Label",
                                                    comment: "Label for button to purchase the shipping label on the shipping label creation screen")
            static let purchaseFormat = NSLocalizedString("wooShipping.createLabels.bottomSheet.purchaseFormat",
                                                          value: "Purchase Label · %1$@",
                                                          comment: "Label for button to purchase the shipping label on the shipping label creation screen, " +
                                                          "including the label price. Reads like: 'Purchase Label · $7.63'")
        }
    }
}
