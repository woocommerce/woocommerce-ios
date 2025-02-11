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

    /// Whether the origin address list sheet is presented.
    @State private var isOriginAddressListPresented = false

    /// Whether the destination address is verified.
    private var isDestinationAddressVerified: Bool {
        viewModel.destinationAddressStatus == .verified
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.verticalSpacing) {
                    if viewModel.canViewLabel, let postPurchase = viewModel.postPurchase {
                        WooShippingPostPurchaseView(viewModel: postPurchase)
                    }

                    WooShippingItems(viewModel: viewModel.items)

                    WooShippingHazmat(enabled: !viewModel.canViewLabel)

                    WooShippingCustomsRow(informationIsCompleted: viewModel.customsInformationIsCompleted,
                                          customsFormViewModel: viewModel.customsFormViewModel)
                        .padding(.bottom, 16)
                        .renderedIf(viewModel.customsFormRequired)

                    if viewModel.canViewLabel {
                        EmptyView()
                    } else if let package = viewModel.selectedPackage,
                              let shippingService = viewModel.shippingService {
                        WooShippingSelectedPackageView(package: package,
                                                       totalWeight: $viewModel.shipmentWeight,
                                                       updateSelectedPackage: viewModel.selectPackage)
                        WooShippingServiceView(viewModel: shippingService)
                    } else {
                        WooShippingPackageAndRatePlaceholder(onSelectPackage: viewModel.selectPackage)
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) {
                ExpandableBottomSheet(onChangeOfExpansion: { isExpanded in
                    isShipmentDetailsExpanded = isExpanded
                }) {
                    VStack {
                        collapsedBottomSheet
                            .renderedIf(!isShipmentDetailsExpanded)
                        bottomSheetPurchaseActions
                            .renderedIf(!viewModel.canViewLabel)
                    }
                    .padding(.horizontal, Layout.bottomSheetPadding)
                } expandableContent: {
                    VStack(alignment: .leading, spacing: Layout.bottomSheetSpacing) {
                        if isiPhonePortrait {
                            Text(Localization.BottomSheet.orderDetails)
                                .footnoteStyle()
                        }
                        CollapsibleHStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: .zero) {
                            shipFromAddress
                            Divider()
                            shipToAddress
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
                .ignoresSafeArea(edges: .horizontal)
                .sheet(isPresented: $isOriginAddressListPresented) {
                    WooShippingOriginAddressListView(viewModel: viewModel.originAddresses)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .shippingWeightUnit(viewModel.weightUnit)
            .shippingDimensionsUnit(viewModel.dimensionsUnit)
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
    }
}

private extension WooShippingCreateLabelsView {
    /// View for elements only displayed on the collapsed bottom sheet.
    var collapsedBottomSheet: some View {
        VStack {
            Text(Localization.BottomSheet.shipmentDetails)
                .foregroundStyle(Color(.primary))
                .bold()
            addressVerificationNotice(with: viewModel.destinationAddressStatusNoticeLabel)
                .onTapGesture {
                    // TODO: Start address editing/verification flow if needed (if destination address is unverified).
                }
        }
    }

    /// View for the purchase-related actions, such as "Mark as completed" toggle and purchase button.
    var bottomSheetPurchaseActions: some View {
        Group {
            if isiPhonePortrait {
                VStack(spacing: Layout.bottomSheetSpacing) {
                    if isShipmentDetailsExpanded {
                        Toggle(Localization.BottomSheet.markComplete, isOn: $viewModel.markOrderComplete)
                            .font(.subheadline)
                            .tint(Color(.primary))
                    }
                    if isShipmentDetailsExpanded || viewModel.selectedPackage != nil {
                        purchaseButton
                    }
                }
            }
            else {
                HStack(spacing: Layout.bottomSheetSpacing) {
                    if viewModel.selectedPackage != nil || isShipmentDetailsExpanded {
                        Toggle(Localization.BottomSheet.markComplete, isOn: $viewModel.markOrderComplete)
                            .font(.subheadline)
                            .tint(Color(.primary))
                            .fixedSize(horizontal: false, vertical: true)
                        purchaseButton
                    }
                }
            }
        }
    }

    /// View showing the origin ("Ship From") address.
    var shipFromAddress: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.bottomSheetSpacing) {
            Text(Localization.BottomSheet.shipFrom)
                .trackSize(size: $shipmentDetailsShipFromSize)
            Button {
                isOriginAddressListPresented = true
            } label: {
                HStack {
                    Text(viewModel.originAddress)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "ellipsis")
                        .frame(width: Layout.ellipsisWidth)
                        .bold()
                }
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(Layout.bottomSheetPadding)
    }

    /// View showing the destination ("Ship To") address.
    var shipToAddress: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.bottomSheetSpacing) {
            Text(Localization.BottomSheet.shipTo)
                .frame(width: shipmentDetailsShipFromSize.width, alignment: .leading)
            VStack(alignment: .leading) {
                if let addressLines = viewModel.destinationAddressLines {
                    ForEach(addressLines, id: \.self) { addressLine in
                        Text(addressLine)
                            .if(addressLine == addressLines.first) { line in
                                line.bold()
                            }
                    }
                }
                addressVerificationLabel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Layout.bottomSheetPadding)
    }

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

    /// View showing the address verification status for a destination address.
    var addressVerificationLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: isDestinationAddressVerified ? "checkmark.circle" : "exclamationmark.circle")
            Text(Localization.AddressVerification.label(for: viewModel.destinationAddressStatus))
        }
        .font(.subheadline)
        .foregroundStyle(isDestinationAddressVerified ? Layout.green : Layout.red)
    }

    /// View showing a notice about the destination address verification status.
    @ViewBuilder
    func addressVerificationNotice(with label: String?) -> some View {
        if let label = viewModel.destinationAddressStatusNoticeLabel {
            HStack(spacing: 8) {
                Image(systemName: isDestinationAddressVerified ? "checkmark.circle" : "exclamationmark.circle")
                Text(label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    withAnimation {
                        viewModel.destinationAddressStatusNoticeLabel = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .renderedIf(!isDestinationAddressVerified)
                }
            }
            .font(.subheadline)
            .foregroundStyle(isDestinationAddressVerified ? Layout.green : Layout.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: isDestinationAddressVerified ? .withColorStudio(.green, shade: .shade0) : .withColorStudio(.red, shade: .shade0))))
        }
    }
}

// MARK: Store Options
extension EnvironmentValues {
    @Entry var shippingWeightUnit: String = ServiceLocator.shippingSettingsService.weightUnit ?? ""
    @Entry var shippingDimensionsUnit: String = ServiceLocator.shippingSettingsService.dimensionUnit ?? ""
}

extension View {
    func shippingWeightUnit(_ weightUnit: String) -> some View {
        environment(\.shippingWeightUnit, weightUnit)
    }

    func shippingDimensionsUnit(_ dimensionsUnit: String) -> some View {
        environment(\.shippingDimensionsUnit, dimensionsUnit)
    }
}

private extension WooShippingCreateLabelsView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 32
        static let rowHeight: CGFloat = 32
        static let chevronSize: CGFloat = 30
        static let ellipsisWidth: CGFloat = 22
        static let bottomSheetSpacing: CGFloat = 16
        static let bottomSheetPadding: CGFloat = 16
        static let green = Color(UIColor(light: .withColorStudio(.green, shade: .shade60),
                                         dark: .withColorStudio(.green, shade: .shade40)))
        static let red = Color(UIColor(light: .withColorStudio(.red, shade: .shade60),
                                       dark: .withColorStudio(.red, shade: .shade40)))
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
            static let markComplete = NSLocalizedString("wooShipping.createLabels.bottomSheet.afterPurchaseMarkComplete",
                                                        value: "After purchasing a label, mark this order as complete and notify the customer",
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

        enum AddressVerification {
            static func label(for status: WooShippingCreateLabelsViewModel.DestinationAddressStatus) -> String {
                switch status {
                case .verified:
                    return verified
                case .unverified:
                    return unverified
                case .missing:
                    return missing
                }
            }
            static let verified = NSLocalizedString("wooShipping.createLabels.addressVerification.verified",
                                                    value: "Address verified",
                                                    comment: "Label when an address is verified on the shipping label creation screen")
            static let unverified = NSLocalizedString("wooShipping.createLabels.addressVerification.unverified",
                                                      value: "Unverified address",
                                                      comment: "Label when an address is unverified on the shipping label creation screen")
            static let missing = NSLocalizedString("wooShipping.createLabels.addressVerification.missing",
                                                   value: "Missing address",
                                                   comment: "Label when an address is missing on the shipping label creation screen")
        }
    }
}
