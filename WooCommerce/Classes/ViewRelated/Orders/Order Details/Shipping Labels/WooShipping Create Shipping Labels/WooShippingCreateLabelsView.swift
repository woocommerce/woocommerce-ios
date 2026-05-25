import SwiftUI

/// Hosting controller for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewHostingController: UIHostingController<WooShippingCreateLabelsView> {
    let viewModel: WooShippingCreateLabelsViewModel

    init(viewModel: WooShippingCreateLabelsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WooShippingCreateLabelsView(viewModel: viewModel))
    }

    dynamic required init?(coder aDecoder: NSCoder) {
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
    @Environment(\.sizeCategory) private var sizeCategory

    private var isiPhonePortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }

    /// Tracks the size of the "Ship from" label in the Shipment Details address section.
    @State private var shipmentDetailsShipFromSize: CGSize = .zero

    /// Whether the shipment details bottom sheet is expanded.
    @State private var isShipmentDetailsExpanded = false

    /// Whether the origin address list sheet is presented.
    @State private var isOriginAddressListPresented = false

    @State private var showingCustomsForm = false
    @State private var showingSplitShipments = false

    /// Whether the destination address is verified.
    private var isDestinationAddressVerified: Bool {
        viewModel.destinationAddressStatus == .verified
    }

    /// Whether the "Purchase" button should be rendered
    private var shouldShowPurchaseButton: Bool {
        return isShipmentDetailsExpanded ||
        !sizeCategory.isAccessibilityCategory ||
        viewModel.isPurchaseButtonEnabled
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .ready:
                    VStack(spacing: 0) {
                        if viewModel.shipments.count > 1 {
                            topTabView
                            Divider()
                        }
                        mainView
                    }
                case .missingRequiredData:
                    missingDataState
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.state == .ready && viewModel.hazmatNotice == nil {
                    expandableBottomSheet
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
                    .disabled(viewModel.isPurchasingLabel)
                }
            }
            .sheet(isPresented: $isOriginAddressListPresented) {
                WooShippingOriginAddressListView(viewModel: viewModel.originAddresses)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $viewModel.addressToEdit) { addressToEdit in
                NavigationStack {
                    WooShippingEditAddressView(viewModel: addressToEdit)
                        .navigationTitle(Localization.BottomSheet.editDestination)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showingCustomsForm) {
                WooShippingCustomsForm(viewModel: viewModel.currentShipmentDetailsViewModel.customsFormViewModel)
            }
            .notice($viewModel.labelPurchaseErrorNotice, autoDismiss: false)
            .notice($viewModel.hazmatNotice)
            .notice($viewModel.refundNotice)
            .fullScreenCover(isPresented: $showingSplitShipments) {
                WooShippingSplitShipmentsView(viewModel: viewModel.splitShipmentsViewModel) { updatedShipments in
                    viewModel.updateShipments(updatedShipments)
                    isShipmentDetailsExpanded = false
                }
            }
            .sheet(isPresented: $viewModel.showingPaymentMethods) {
                if let paymentMethodsViewModel = viewModel.paymentMethodsViewModel {
                    WooShippingPaymentMethodsView(viewModel: paymentMethodsViewModel,
                                                  onAccountSettingsUpdate: { settings in
                        viewModel.didUpdateAccountSettings(settings)
                        viewModel.showingPaymentMethods = false
                    })
                    .presentationDetents([.fraction(0.7), .large])
                }
            }
            .sheet(isPresented: $viewModel.shouldShowUPSTermsAndConditions) {
                if let termsViewModel = viewModel.upsTermsViewModel {
                    UPSTermsView(viewModel: termsViewModel, onConfirmation: {
                        viewModel.shouldShowUPSTermsAndConditions = false
                        Task { @MainActor in
                            await viewModel.purchaseLabel(shouldRefreshPackageAndRate: true)
                        }
                    })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.shouldShowFedExTermsAndConditions) {
                FedExTermsView(viewModel: viewModel.fedExTermsViewModel, onConfirmation: {
                    viewModel.shouldShowFedExTermsAndConditions = false
                    Task { @MainActor in
                        await viewModel.purchaseLabel(shouldRefreshPackageAndRate: true)
                    }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

private extension WooShippingCreateLabelsView {
    var tabs: [TopTabItem<EmptyView>] {
        viewModel.shipments.enumerated().map { (index, shipment) in
            TopTabItem(name: String.localizedStringWithFormat(Localization.shipmentFormat, index + 1),
                       icon: shipment.isPurchased ? Layout.purchasedIcon : nil,
                       customAccessibilityValue: shipment.isPurchased ?
                           Localization.Accessibility.shipmentTabFulfilled :
                           Localization.Accessibility.shipmentTabUnfulfilled,
                       content: {
                EmptyView()
            })
        }
    }

    var topTabView: some View {
        HStack(spacing: 0) {
            TopTabView(tabs: tabs,
                       showContent: false,
                       showDividerBelowTabs: false,
                       selectedTabIndex: $viewModel.selectedShipmentIndex,
                       tabsContainerHorizontalPadding: nil,
                       selectedStateColor: .accentColor,
                       unselectedStateColor: .secondary,
                       selectedTabIndicatorHeight: Layout.selectedTabIndicatorHeight,
                       tabPadding: Layout.tabPadding,
                       tabsNameFont: Font.subheadline.bold(),
                       tabsIconSize: Layout.purchasedIconWidth,
                       tabsIconAlignment: .trailing,
                       tabsIconForegroundColor: Layout.green,
                       tabItemContentHorizontalPadding: Layout.tabItemContentHorizontalPadding,
                       tabItemContentVerticalPadding: Layout.tabItemContentVerticalPadding)
            .overlay(alignment: .trailing) {
                LinearGradient(gradient: Gradient(colors: [.clear, Color(.basicBackground)]), startPoint: .leading, endPoint: .center)
                    .frame(width: Layout.gradientViewWidth)
                    .renderedIf(viewModel.selectedShipmentIndex < viewModel.shipmentDetailViewModels.count - 1)
            }

            Button {
                showingSplitShipments = true
            } label: {
                Image(systemName: "pencil")
                    .padding(.horizontal)
            }
            .accessibilityHint(Localization.Accessibility.editButtonHint)
            .renderedIf(viewModel.editSplitShipmentsOptionVisible)
        }
        .disabled(viewModel.isPurchasingLabel)
    }

    @ViewBuilder
    var mainView: some View {
        ScrollView {
            VStack(spacing: Layout.verticalSpacing) {
                if viewModel.splitShipmentsRowVisible {
                    WooShippingSplitShipmentsRow(onShowingSplitShipments: {
                        showingSplitShipments = true
                    })
                }
                WooShippingShipmentDetailsView(viewModel: viewModel.currentShipmentDetailsViewModel)
                    .disabled(viewModel.isPurchasingLabel)
            }
            .padding(Layout.contentSpacing)
        }
    }

    var expandableBottomSheet: some View {
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
                            .padding(.trailing, -Layout.bottomSheetPadding)
                        if let line = viewModel.paymentMethodLine {
                            paymentMethod(line)
                            Divider()
                                .padding(.trailing, -Layout.bottomSheetPadding)
                        }
                        shipmentDetails
                    }
                } else {
                    HStack(alignment: .top, spacing: Layout.bottomSheetPadding) {
                        VStack(spacing: Layout.bottomSheetPadding) {
                            orderDetails
                            if let line = viewModel.paymentMethodLine {
                                Divider()
                                paymentMethod(line)
                            }
                        }
                        Divider()
                            .padding(.trailing, -Layout.bottomSheetPadding)
                        shipmentDetails
                    }
                }
            }
            .padding([.bottom, .horizontal], Layout.bottomSheetPadding)
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    var missingDataState: some View {
        VStack(spacing: Layout.contentSpacing) {
            Image(uiImage: .grayErrorIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(Localization.missingDataError)
                .multilineTextAlignment(.center)
            Button(Localization.retryCTA) {
                Task {
                    await viewModel.loadRequiredData()
                }
            }
        }
    }

    /// View for elements only displayed on the collapsed bottom sheet.
    var collapsedBottomSheet: some View {
        VStack {
            Text(Localization.BottomSheet.shipmentDetails)
                .foregroundStyle(Color(.primary))
                .bold()
                .lineLimit(1)
                .scaledToFill()
                .minimumScaleFactor(0.5)

            if viewModel.shouldShowNotices {
                if let originAddressUnverifiedNoticeLabel = viewModel.originAddressUnverifiedNoticeLabel {
                    // Unverified notice for origin address
                    verificationNotice(with: originAddressUnverifiedNoticeLabel,
                                       isVerified: false,
                                       onDismiss: {
                        withAnimation {
                            viewModel.originAddressUnverifiedNoticeLabel = nil
                        }
                    },
                                       onTap: {
                        viewModel.editSelectedOriginAddress()
                    })
                } else if let destinationPhoneNumberNoticeLabel = viewModel.destinationPhoneNumberNoticeLabel {
                    // Phone number notice for destination address
                    verificationNotice(
                        with: destinationPhoneNumberNoticeLabel,
                        isVerified: false,
                        onDismiss: {
                            withAnimation {
                                viewModel.destinationPhoneNumberNoticeLabel = nil
                            }
                        },
                        onTap: {
                            viewModel.editDestinationAddress()
                        }
                    )
                } else if let destinationAddressStatusNoticeLabel = viewModel.destinationAddressStatusNoticeLabel {
                    // Verification notice for destination address
                    verificationNotice(with: destinationAddressStatusNoticeLabel,
                                       isVerified: isDestinationAddressVerified,
                                       onDismiss: {
                        withAnimation {
                            viewModel.destinationAddressStatusNoticeLabel = nil
                        }
                    },
                                       onTap: {
                        if !isDestinationAddressVerified {
                            viewModel.editDestinationAddress()
                        }
                    })
                } else if let itnMissingNoticeLabel = viewModel.currentShipmentDetailsViewModel.itnMissingNoticeLabel {
                    // Verification notice for missing ITN in customs form
                    verificationNotice(with: itnMissingNoticeLabel,
                                       isVerified: false,
                                       onDismiss: {
                        withAnimation {
                            viewModel.currentShipmentDetailsViewModel.itnMissingNoticeLabel = nil
                        }
                    },
                                       onTap: {
                        showingCustomsForm = true
                    })
                }
            }
        }
    }

    /// View for the purchase-related actions, such as "Mark as completed" toggle and purchase button.
    var bottomSheetPurchaseActions: some View {
        Group {
            if isiPhonePortrait {
                VStack(spacing: Layout.bottomSheetSpacing) {
                    if isShipmentDetailsExpanded && !viewModel.isOrderCompleted {
                        Toggle(isOn: $viewModel.markOrderComplete) {
                            Text(Localization.BottomSheet.markComplete)
                                .font(.subheadline)
                                .lineLimit(Layout.toggleTextLineLimit)
                                .dynamicTypeSize(...Layout.toggleTextMaxDynamicTypeSizePortrait)
                        }
                        .tint(Color(.primary))
                    }
                    if shouldShowPurchaseButton || viewModel.currentShipmentDetailsViewModel.selectedPackage != nil {
                        purchaseButton
                    }
                }
            }
            else {
                HStack(spacing: Layout.bottomSheetSpacing) {
                    if viewModel.currentShipmentDetailsViewModel.selectedPackage != nil || isShipmentDetailsExpanded {
                        Toggle(isOn: $viewModel.markOrderComplete) {
                            Text(Localization.BottomSheet.markComplete)
                                .font(.subheadline)
                                .lineLimit(Layout.toggleTextLineLimit)
                                .dynamicTypeSize(...Layout.toggleTextMaxDynamicTypeSizeLandscape)
                        }
                        .tint(Color(.primary))
                        .fixedSize(horizontal: false, vertical: true)
                        .renderedIf(!viewModel.isOrderCompleted)

                        if shouldShowPurchaseButton {
                            purchaseButton
                        }
                    }
                }
            }
        }
    }

    /// View showing the origin ("Ship From") address.
    var shipFromAddress: some View {
        AdaptiveStack(
            horizontalAlignment: .leading,
            verticalAlignment: .firstTextBaseline,
            spacing: Layout.bottomSheetSpacing
        ) {
            Text(Localization.BottomSheet.shipFrom)
                .trackSize(size: $shipmentDetailsShipFromSize)

            if viewModel.canViewLabel {
                Group {
                    if let addressLines = viewModel.originAddressLines {
                        AddressLinesView(addressLines: addressLines)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(
                    alignment: .leading,
                    spacing: Layout.verticalSpacing
                ) {
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
                    .disabled(viewModel.isPurchasingLabel)

                    if viewModel.isOriginAddressUnverified {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle")
                            Text(Localization.AddressVerification.unverified)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Layout.red)
                    }
                }
            }
        }
        .padding(Layout.bottomSheetPadding)
    }

    /// View showing the destination ("Ship To") address.
    var shipToAddress: some View {
        AdaptiveStack(
            horizontalAlignment: .leading,
            verticalAlignment: .firstTextBaseline,
            spacing: Layout.bottomSheetSpacing
        ) {
            Text(Localization.BottomSheet.shipTo)
                .frame(width: shipmentDetailsShipFromSize.width, alignment: .leading)
            VStack(
                alignment: .leading,
                spacing: Layout.verticalSpacing
            ) {
                if let addressLines = viewModel.destinationAddressLines {
                    AddressLinesView(addressLines: addressLines)
                }
                addressVerificationLabel
                    .renderedIf(!viewModel.canViewLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PencilEditButton {
                viewModel.editDestinationAddress()
            }
            .buttonStyle(TextButtonStyle())
            .renderedIf(!viewModel.canViewLabel)
            .disabled(viewModel.isPurchasingLabel)
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
            HStack {
                Image(uiImage: .productIcon)
                    .frame(width: Layout.iconSize)
                Text(viewModel.orderItems.itemsCountLabel)
                    .bold()
                Spacer()
                Text(viewModel.orderItems.itemsPriceLabel)
            }
            ForEach(viewModel.shippingLines) { shippingLine in
                HStack {
                    Image(uiImage: .shippingIcon)
                        .frame(width: Layout.iconSize)
                    Text(shippingLine.title)
                        .bold()
                        .lineLimit(nil)
                    Spacer()
                    Text(shippingLine.formattedTotal)
                }
            }
        }
    }

    func paymentMethod(_ line: WooShippingPaymentMethodLine) -> some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text(Localization.BottomSheet.paymentMethod)
                .footnoteStyle()
            switch line {
            case .add:
                addPaymentMethodLine
            case .card(let cardLineViewModel):
                cardPaymentMethodLine(cardLineViewModel)
            }
        }
    }

    var addPaymentMethodLine: some View {
        Button(action: {
            viewModel.showingPaymentMethods = true
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(Localization.BottomSheet.addPaymentMethod)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }

    func cardPaymentMethodLine(
        _ cardLineViewModel: WooShippingPaymentMethodLine.CardPaymentMethodLineViewModel
    ) -> some View {
        Button(action: {
            viewModel.showingPaymentMethods = true
        }) {
            HStack {
                Text(cardLineViewModel.title)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .renderedIf(cardLineViewModel.isEditable)
            }
        }
        .disabled(!cardLineViewModel.isEditable)
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
        }
    }

    func shippingRateRow(label: String, amount: String?) -> some View {
        HStack {
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
            Task {
                await viewModel.purchaseLabel(shouldRefreshPackageAndRate: false)
            }
        } label: {
            Text(Localization.BottomSheet.purchaseLabel(with: viewModel.totalCost))
                .lineLimit(1)
                .scaledToFill()
                .minimumScaleFactor(0.5)
        }
        .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isPurchasingLabel))
        .disabled(!viewModel.isPurchaseButtonEnabled)
    }

    /// View showing the address verification status for a destination address.
    @ViewBuilder
    var addressVerificationLabel: some View {
        if let destinationAddressStatus = viewModel.destinationAddressStatus {
            HStack(spacing: 4) {
                Image(systemName: isDestinationAddressVerified ? "checkmark.circle" : "exclamationmark.circle")
                Text(Localization.AddressVerification.label(for: destinationAddressStatus))
            }
            .font(.subheadline)
            .foregroundStyle(isDestinationAddressVerified ? Layout.green : Layout.red)
        }
    }

    /// View showing a notice about a verification status.
    @ViewBuilder
    func verificationNotice(with label: String,
                            isVerified: Bool,
                            onDismiss: @escaping () -> Void,
                            onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isVerified ? "checkmark.circle" : "exclamationmark.circle")
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .renderedIf(!isVerified)
            }
        }
        .font(.subheadline)
        .foregroundStyle(isVerified ? Layout.green : Layout.red)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color(uiColor: isVerified ? .withColorStudio(.green, shade: .shade0) : .withColorStudio(.red, shade: .shade0))))
        .onTapGesture(perform: onTap)
    }
}

private struct AddressLinesView: View {
    let addressLines: [String]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(addressLines, id: \.self) { addressLine in
                Text(addressLine)
                    .if(addressLine == addressLines.first) { line in
                        line.bold()
                    }
            }
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
        static let contentSpacing: CGFloat = 16
        static let bottomSheetSpacing: CGFloat = 16
        static let bottomSheetPadding: CGFloat = 16
        static let errorIconSize: CGFloat = 86
        static let green = Color(UIColor(light: .withColorStudio(.green, shade: .shade60),
                                         dark: .withColorStudio(.green, shade: .shade40)))
        static let red = Color(UIColor(light: .withColorStudio(.red, shade: .shade60),
                                       dark: .withColorStudio(.red, shade: .shade40)))
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        static let tabPadding: CGFloat = 9.0
        static let tabItemContentHorizontalPadding: CGFloat = 16.0
        static let tabItemContentVerticalPadding: CGFloat = 9.0
        static let gradientViewWidth: CGFloat = 32
        static let purchasedIconWidth: CGFloat = 16
        static let purchasedIcon = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)

        static let toggleTextLineLimit = 3
        static let toggleTextMaxDynamicTypeSizePortrait = DynamicTypeSize.accessibility1
        static let toggleTextMaxDynamicTypeSizeLandscape = DynamicTypeSize.xxxLarge
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

        enum Accessibility {
            static let editButtonHint = NSLocalizedString(
                "wooShipping.createLabel.editButton.accessibility.hint",
                value: "Opens the shipments editing form.",
                comment: "Accessibility hint of the button to open the shipments editing form.")
            static let shipmentTabFulfilled = NSLocalizedString(
                "wooShipping.createLabel.shipmentTab.accessibility.value.fulfilled",
                value: "Fulfilled.",
                comment: "Accessibility value indicating that the shipment of a tab is fulfilled.")
            static let shipmentTabUnfulfilled = NSLocalizedString(
                "wooShipping.createLabel.shipmentTab.accessibility.value.unfulfilled",
                value: "Unfulfilled.",
                comment: "Accessibility value indicating that the shipment of a tab is unfulfilled.")
        }

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

            static let paymentMethod = NSLocalizedString(
                "wooShipping.createLabels.bottomSheet.paymentMethod",
                value: "Payment Method",
                comment: "Header for payment method section on the shipping label creation screen"
            ).localizedUppercase

            static let addPaymentMethod = NSLocalizedString(
                "wooShipping.createLabels.bottomSheet.addPaymentMethod",
                value: "Add payment method",
                comment: "Label for the option to add a payment method on the shipping label creation screen"
            )

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
            static let editDestination = NSLocalizedString("wooShipping.createLabels.bottomSheet.editDestination",
                                                          value: "Edit Destination",
                                                          comment: "Title for the edit destination address screen in the shipping label creation flow")
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

        static let missingDataError = NSLocalizedString(
            "wooShipping.createLabels.missingDataError",
            value: "We are unable to load required data",
            comment: "Error message when loading required data failed on the shipping label creation screen"
        )
        static let retryCTA = NSLocalizedString(
            "wooShipping.createLabels.retryCTA",
            value: "Retry",
            comment: "Button to retry loading data on the shipping label creation screen"
        )
        static let shipmentFormat = NSLocalizedString(
            "wooShipping.createLabels.shipmentFormat",
            value: "Shipment %1$d",
            comment: "Label for a shipment during shipping label creation. The placeholder is the index of the shipment. Reads like: 'Shipment 1'"
        )
    }
}
