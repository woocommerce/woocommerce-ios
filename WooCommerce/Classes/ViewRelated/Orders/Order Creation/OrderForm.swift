import SwiftUI
import Combine

/// Hosting controller that wraps an `OrderForm` view.
///
final class OrderFormHostingController: UIHostingController<OrderFormPresentationWrapper> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []
    private let viewModel: EditableOrderViewModel

    init(viewModel: EditableOrderViewModel) {
        self.viewModel = viewModel
        let flow: WooAnalyticsEvent.Orders.Flow = {
            switch viewModel.flow {
                case .creation:
                    return .creation
                case .editing:
                    return .editing
            }
        }()
        super.init(rootView: OrderFormPresentationWrapper(flow: flow, dismissLabel: .cancelButton, viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismissHandler = { [weak self] in
            guard viewModel.canBeDismissed else {
                self?.presentDiscardChangesActionSheet {
                    self?.discardOrderAndDismiss()
                }
                return
            }
            self?.dismiss(animated: true)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }
}

/// Intercepts back navigation (selecting back button or swiping back).
///
extension OrderFormHostingController {
    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.canBeDismissed else {
            presentDiscardChangesActionSheet(onDiscard: { [weak self] in
                self?.discardOrderAndPop()
            })
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension OrderFormHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.canBeDismissed
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentDiscardChangesActionSheet(onDiscard: { [weak self] in
            self?.discardOrderAndDismiss()
        })
    }
}

/// Private methods
///
private extension OrderFormHostingController {
    func presentDiscardChangesActionSheet(onDiscard: @escaping () -> Void) {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: onDiscard)
    }

    func discardOrderAndDismiss() {
        viewModel.discardOrder()
        dismiss(animated: true)
    }

    func discardOrderAndPop() {
        viewModel.discardOrder()
        navigationController?.popViewController(animated: true)
    }
}

struct OrderFormPresentationWrapper: View {
    /// Style of the dismiss button label.
    enum DismissLabel {
        /// Text label with Cancel copy.
        case cancelButton
        /// Backward chevron image.
        case backButton
    }

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismissHandler: (() -> Void) = {}

    let flow: WooAnalyticsEvent.Orders.Flow

    let dismissLabel: DismissLabel

    @ObservedObject var viewModel: EditableOrderViewModel

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
            AdaptiveModalContainer(
                primaryView: { presentProductSelector in
                    OrderForm(dismissHandler: dismissHandler,
                              flow: flow,
                              viewModel: viewModel,
                              presentProductSelector: presentProductSelector)
                    // When we're modal-on-modal, show the notices on both screens so they're definitely visible
                    .if(horizontalSizeClass == .compact, transform: {
                        $0
                            .notice($viewModel.autodismissableNotice)
                            .notice($viewModel.fixedNotice, autoDismiss: false)
                    })
                },
                secondaryView: { isShowingProductSelector in
                    if let productSelectorViewModel = viewModel.productSelectorViewModel {
                        ProductSelectorView(configuration: .loadConfiguration(for: horizontalSizeClass),
                                            isPresented: isShowingProductSelector,
                                            viewModel: productSelectorViewModel)
                        .sheet(item: $viewModel.productToConfigureViewModel) { viewModel in
                            ConfigurableBundleProductView(viewModel: viewModel)
                        }
                        // When we're modal-on-modal, show the notices on both screens so they're definitely visible
                        .if(horizontalSizeClass == .compact, transform: {
                            $0
                                .notice($viewModel.autodismissableNotice)
                                .notice($viewModel.fixedNotice, autoDismiss: false)
                        })
                    }
                },
                dismissBarButton: {
                    Button {
                        // By only calling the dismissHandler here, we wouldn't sync the selected items on dismissal
                        // this is normally done via a callback through the ProductSelector's onCloseButtonTapped(),
                        // but on split views we move this responsibility to the AdaptiveModalContainer
                        viewModel.syncOrderItemSelectionStateOnDismiss()
                        dismissHandler()
                    } label: {
                        switch dismissLabel {
                            case .cancelButton:
                                Text(OrderForm.Localization.cancelButton)
                            case .backButton:
                                Image(systemName: "chevron.backward")
                                    .headlineLinkStyle()
                        }
                    }
                    .accessibilityIdentifier(OrderForm.Accessibility.cancelButtonIdentifier)
                },
                isShowingSecondaryView: $viewModel.isProductSelectorPresented)
            // When we're side-by-side, show the notices over the combined screen
            .if(horizontalSizeClass == .regular, transform: {
                $0
                    .notice($viewModel.autodismissableNotice)
                    .notice($viewModel.fixedNotice, autoDismiss: false)
            })
        } else {
            OrderForm(dismissHandler: dismissHandler, flow: flow, viewModel: viewModel, presentProductSelector: nil)
        }
    }
}

private extension ProductSelectorView.Configuration {
    static func loadConfiguration(for sizeClass: UserInterfaceSizeClass?) -> ProductSelectorView.Configuration {
        guard let sizeClass else {
            DDLogWarn("No size class when determining configuration for product selector")
            return .addProductToOrder()
        }

        switch sizeClass {
        case .compact:
            return .addProductToOrder()
        case .regular:
            return .splitViewAddProductToOrder()
        @unknown default:
            DDLogError("Size class unknown when determining configuration for product selector")
            return .addProductToOrder()
        }
    }
}

/// View to create or edit an order
///
struct OrderForm: View {
    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismissHandler: (() -> Void) = {}

    let flow: WooAnalyticsEvent.Orders.Flow

    @ObservedObject var viewModel: EditableOrderViewModel

    let presentProductSelector: (() -> Void)?

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// Fix for breaking navbar button
    @State private var navigationButtonID = UUID()

    @State private var shouldShowNewTaxRateSelector = false
    @State private var shouldShowStoredTaxRateSheet = false

    @State private var shouldShowInformationalCouponTooltip = false

    @State private var shouldShowGiftCardForm = false

    @Environment(\.adaptiveModalContainerPresentationStyle) var presentationStyle

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isLoading: Bool {
        viewModel.paymentDataViewModel.isLoading
    }

    var body: some View {
        orderFormSummary(presentProductSelector)
            .onAppear {
                updateSelectionSyncApproach(for: presentationStyle)
            }
            .onChange(of: horizontalSizeClass) { _ in
                viewModel.saveInFlightOrderNotes()
                viewModel.saveInflightCustomerDetails()
            }
    }

    private func updateSelectionSyncApproach(for presentationStyle: AdaptiveModalContainerPresentationStyle?) {
        switch presentationStyle {
        case .none, .modalOnModal:
            viewModel.selectionSyncApproach = .onSelectorButtonTap
        case .sideBySide:
            viewModel.selectionSyncApproach = .onRecalculateButtonTap
        }
    }

    @ViewBuilder private func orderFormSummary(_ presentProductSelector: (() -> Void)?) -> some View {
        GeometryReader { geometry in
            ScrollViewReader { scroll in
                ScrollView {
                    Group {
                        VStack(spacing: Layout.noSpacing) {
                            Spacer(minLength: Layout.sectionSpacing)

                            Group {
                                Divider() // Needed because `NonEditableOrderBanner` does not have a top divider
                                NonEditableOrderBanner(width: geometry.size.width)
                            }
                            .renderedIf(viewModel.shouldShowNonEditableIndicators)

                            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
                                Group {
                                    OrderStatusSection(viewModel: viewModel, topDivider: !viewModel.shouldShowNonEditableIndicators)
                                    Spacer(minLength: Layout.sectionSpacing)
                                }
                                .renderedIf(flow == .editing)
                            } else {
                                OrderStatusSection(viewModel: viewModel, topDivider: !viewModel.shouldShowNonEditableIndicators)
                                Spacer(minLength: Layout.sectionSpacing)
                            }

                            ProductsSection(scroll: scroll,
                                            flow: flow,
                                            presentProductSelector: presentProductSelector,
                                            viewModel: viewModel,
                                            navigationButtonID: $navigationButtonID,
                                            isLoading: isLoading)
                            .disabled(viewModel.shouldShowNonEditableIndicators)

                            Group {
                                Divider()
                                Spacer(minLength: Layout.sectionSpacing)
                                Divider()
                            }
                            .renderedIf(viewModel.shouldSplitProductsAndCustomAmountsSections)

                            OrderCustomAmountsSection(viewModel: viewModel, sectionViewModel: viewModel.customAmountsSectionViewModel)
                                .disabled(viewModel.shouldShowNonEditableIndicators)

                            Divider()

                            Spacer(minLength: Layout.sectionSpacing)

                            Group {
                                OrderShippingSection(viewModel: viewModel.shippingLineViewModel)
                                    .disabled(viewModel.shouldShowNonEditableIndicators)
                                Spacer(minLength: Layout.sectionSpacing)
                            }
                            .renderedIf(viewModel.shippingLineViewModel.shippingLineRows.isNotEmpty)

                            AddOrderComponentsSection(
                                viewModel: viewModel.paymentDataViewModel,
                                shippingLineViewModel: viewModel.shippingLineViewModel,
                                shouldShowCouponsInfoTooltip: $shouldShowInformationalCouponTooltip,
                                shouldShowGiftCardForm: $shouldShowGiftCardForm)
                            .addingTopAndBottomDividers()
                            .disabled(viewModel.shouldShowNonEditableIndicators)

                            Spacer(minLength: Layout.sectionSpacing)
                        }

                        VStack(spacing: Layout.noSpacing) {
                            Group {
                                NewTaxRateSection(text: viewModel.taxRateRowText) {
                                    viewModel.onSetNewTaxRateTapped()
                                    switch viewModel.taxRateRowAction {
                                    case .storedTaxRateSheet:
                                        shouldShowStoredTaxRateSheet = true
                                        viewModel.onStoredTaxRateBottomSheetAppear()
                                    case .taxSelector:
                                        shouldShowNewTaxRateSelector = true
                                    }

                                }
                                .sheet(isPresented: $shouldShowNewTaxRateSelector) {
                                    NewTaxRateSelectorView(viewModel: NewTaxRateSelectorViewModel(siteID: viewModel.siteID,
                                                                                                  onTaxRateSelected: { taxRate in
                                        viewModel.onTaxRateSelected(taxRate)
                                    }),
                                                           taxEducationalDialogViewModel: viewModel.paymentDataViewModel.taxEducationalDialogViewModel,
                                                           onDismissWpAdminWebView: viewModel.paymentDataViewModel.onDismissWpAdminWebViewClosure,
                                                           storeSelectedTaxRate: viewModel.shouldStoreTaxRateInSelectorByDefault)
                                }
                                .sheet(isPresented: $shouldShowStoredTaxRateSheet) {
                                    if #available(iOS 16.0, *) {
                                        storedTaxRateBottomSheetContent
                                            .presentationDetents([.medium])
                                            .presentationDragIndicator(.visible)
                                    } else {
                                        storedTaxRateBottomSheetContent
                                    }
                                }

                                Spacer(minLength: Layout.sectionSpacing)
                            }
                            .renderedIf(viewModel.shouldShowNewTaxRateSection)

                            Divider()

                            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationCustomers) {
                                OrderCustomerSection(viewModel: viewModel.customerSectionViewModel)
                            } else {
                                LegacyOrderCustomerSection(viewModel: viewModel, addressFormViewModel: viewModel.addressFormViewModel)
                            }

                            Group {
                                Divider()

                                Spacer(minLength: Layout.sectionSpacing)

                                Divider()
                            }
                            .renderedIf(viewModel.shouldSplitCustomerAndNoteSections)

                            CustomerNoteSection(viewModel: viewModel)

                            Divider()
                        }
                    }
                    .disabled(viewModel.disabled)
                }
                .accessibilityIdentifier(Accessibility.orderFormScrollViewIdentifier)
                .background(Color(.listBackground).ignoresSafeArea())
                .ignoresSafeArea(.container, edges: [.horizontal])
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                FeedbackBannerPopover(isPresented: $viewModel.shippingLineViewModel.isSurveyPromptPresented,
                                      config: viewModel.shippingLineViewModel.feedbackBannerConfig)

                ExpandableBottomSheet(onChangeOfExpansion: viewModel.orderTotalsExpansionChanged) {
                    VStack(spacing: .zero) {
                        HStack {
                            Text(Localization.orderTotal)
                            Spacer()
                            Text(viewModel.orderTotal)
                                .redacted(reason: isLoading ? .placeholder : [])
                                .shimmering(active: isLoading)

                        }
                        .font(.headline)
                        .padding([.bottom, .horizontal])

                        Divider()
                            .padding([.leading], Layout.dividerLeadingPadding)

                        completedButton
                            .padding()
                    }
                } expandableContent: {
                    OrderPaymentSection(
                        viewModel: viewModel.paymentDataViewModel,
                        shippingLineViewModel: viewModel.shippingLineViewModel,
                        shouldShowGiftCardForm: $shouldShowGiftCardForm)
                    .disabled(viewModel.shouldShowNonEditableIndicators)
                }
                .ignoresSafeArea(edges: .horizontal)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancelButton) {
                    dismissHandler()
                }
                .accessibilityIdentifier(Accessibility.cancelButtonIdentifier)
                .renderedIf(viewModel.shouldShowCancelButton)
            }
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .create:
                    Button(Localization.createButton) {
                        viewModel.onCreateOrderTapped()
                    }
                    .id(navigationButtonID)
                    .accessibilityIdentifier(Accessibility.createButtonIdentifier)
                    .disabled(viewModel.disabled)
                case .loading:
                    ProgressView()
                case .recalculate:
                    Button(Localization.recalculateButton) {
                        viewModel.onRecalculateTapped()
                    }
                    .disabled(viewModel.shouldShowNonEditableIndicators)
                    .accessibilityIdentifier(Accessibility.recalculateButtonIdentifier)
                case .none:
                    EmptyView()
                }
            }
        }
        .wooNavigationBarStyle()
        .onTapGesture {
            shouldShowInformationalCouponTooltip = false
        }
        // Avoids Notice duplication when the feature flag is enabled. These can be removed when the flag is removed.
        .if(!ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm), transform: {
            $0.notice($viewModel.autodismissableNotice)
        })
        .if(!ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm), transform: {
            $0.notice($viewModel.fixedNotice, autoDismiss: false)
        })
    }

    @ViewBuilder private var storedTaxRateBottomSheetContent: some View {
        VStack (alignment: .leading) {
            Text(Localization.storedTaxRateBottomSheetTitle)
                .bodyStyle()
                .padding(.top, Layout.storedTaxRateBottomSheetTopSpace)
                .padding([.leading, .trailing, .bottom])
                .frame(maxWidth: .infinity, alignment: .leading)

            if let taxRateViewModel = viewModel.storedTaxRateViewModel {
                TaxRateRow(viewModel: taxRateViewModel, onSelect: nil)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.storedTaxRateBottomSheetRowCornerRadius)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .padding()
            }

            Button {
                viewModel.onSetNewTaxRateFromBottomSheetTapped()
                shouldShowStoredTaxRateSheet = false
                shouldShowNewTaxRateSelector = true
            } label: {
                Label {
                    Text(Localization.storedTaxRateBottomSheetNewTaxRateButtonTitle)
                        .bodyStyle()
                } icon: {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: Layout.storedTaxRateBottomSheetButtonIconSize * scale,
                               height: Layout.storedTaxRateBottomSheetButtonIconSize * scale)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .padding()

            Button {
                viewModel.onClearAddressFromBottomSheetTapped()
                shouldShowStoredTaxRateSheet = false
            } label: {
                Label {
                    Text(Localization.storedTaxRateBottomSheetClearTaxRateButtonTitle)
                } icon: {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .font(Font.title2.weight(.semibold))
                        .frame(width: Layout.storedTaxRateBottomSheetButtonIconSize * scale,
                               height: Layout.storedTaxRateBottomSheetButtonIconSize * scale)
                }
            }
            .foregroundColor(Color(uiColor: .withColorStudio(.red, shade: .shade60)))
            .padding()

            Spacer()
        }
    }

    @ViewBuilder private var completedButton: some View {
        switch viewModel.doneButtonType {
        case .recalculate(let loading):
            Button {
                viewModel.onRecalculateTapped()
            } label: {
                Text(Localization.recalculateButton)
            }
            .disabled(viewModel.shouldShowNonEditableIndicators)
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: loading))
        case .create(let loading):
            Button {
                viewModel.onCollectPaymentTapped()
            } label: {
                Text(Localization.collectPaymentButton)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: loading))
            .disabled(viewModel.collectPaymentDisabled)
            .accessibilityIdentifier("order-form-collect-payment")
        case .done(let loading):
            Button {
                viewModel.finishEditing()
                dismissHandler()
            } label: {
                Text(Localization.doneButton)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: loading))
            .accessibilityIdentifier(Accessibility.doneButtonIdentifier)
        }
    }
}

private struct NewTaxRateSection: View {
    let text: String
    let onButtonTapped: (() -> Void)

    var body: some View {
        Button(action: onButtonTapped,
               label: {
                    Text(text)
                        .multilineTextAlignment(.center)
                        .padding(OrderForm.Layout.sectionSpacing)
                        .frame(maxWidth: .infinity)
        })
        .background(Color(.listForeground(modal: true)))
        .addingTopAndBottomDividers()
    }
}

// MARK: Order Sections
/// Represents the Products section
///
private struct ProductsSection: View {
    let scroll: ScrollViewProxy

    let flow: WooAnalyticsEvent.Orders.Flow

    let presentProductSelector: (() -> Void)?

    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

    /// Fix for breaking navbar button
    @Binding var navigationButtonID: UUID

    /// Tracks if the order is loading (syncing remotely)
    let isLoading: Bool

    /// Defines whether `AddProductViaSKUScanner` modal is presented.
    ///
    @State private var showAddProductViaSKUScanner: Bool = false

    /// Defines whether the camera permissions sheet check is presented.
    ///
    @State private var showPermissionsSheet: Bool = false

    /// Defines whether we should show a progress view instead of the barcode scanner button.
    ///
    @State private var showAddProductViaSKUScannerLoading: Bool = false

    /// ID for Add Product button
    ///
    @Namespace var addProductButton

    /// ID for Add Product via SKU Scanner button
    ///
    @Namespace var addProductViaSKUScannerButton

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    /// Environment variable that manages the presentation state of the AdaptiveModalContainer view
    /// which is used in the OrderForm for presenting either modally or side-by-side, based on device class size
    ///
    @Environment(\.adaptiveModalContainerPresentationStyle) private var presentationStyle: AdaptiveModalContainerPresentationStyle?

    /// Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private var layoutVerticalSpacing: CGFloat {
        if viewModel.shouldShowProductsSectionHeader {
            return OrderForm.Layout.verticalSpacing
        } else {
            return .zero
        }
    }

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: layoutVerticalSpacing) {
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm)
                    && presentationStyle == .sideBySide
                    && !viewModel.shouldShowProductsSectionHeader {
                    HStack() {
                        scanProductRow
                    }
                }
                HStack {
                    Text(OrderForm.Localization.products)
                        .accessibilityAddTraits(.isHeader)
                        .headlineStyle()

                    Spacer()

                    Image(uiImage: .lockImage)
                        .foregroundColor(Color(.primary))
                        .renderedIf(viewModel.shouldShowNonEditableIndicators)

                    HStack(spacing: OrderForm.Layout.productsHeaderButtonsSpacing) {
                        scanProductButton

                        if let presentProductSelector {
                            Button(action: {
                                presentProductSelector()
                            }) {
                                Image(uiImage: .plusImage)
                            }
                            .accessibilityLabel(OrderForm.Localization.addProductButtonAccessibilityLabel)
                            .id(addProductButton)
                            .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                        } else if !ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
                            Button(action: {
                                viewModel.toggleProductSelectorVisibility()
                            }) {
                                Image(uiImage: .plusImage)
                            }
                            .accessibilityLabel(OrderForm.Localization.addProductButtonAccessibilityLabel)
                            .id(addProductButton)
                            .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                        }
                    }
                    .scaledToFit()
                    .renderedIf(!viewModel.shouldShowNonEditableIndicators)
                }
                .renderedIf(viewModel.shouldShowProductsSectionHeader)

                ForEach(viewModel.productRows) { productRow in
                    CollapsibleProductCard(viewModel: productRow,
                                           flow: flow,
                                           isLoading: isLoading,
                                           shouldDisableDiscountEditing: isLoading,
                                           shouldDisallowDiscounts: viewModel.shouldDisallowDiscounts,
                                           onAddDiscount: viewModel.setDiscountViewModel)
                    .sheet(item: $viewModel.discountViewModel, content: { discountViewModel in
                        ProductDiscountView(viewModel: discountViewModel)
                    })
                    .sheet(item: $viewModel.configurableProductViewModel) { configurableProductViewModel in
                        ConfigurableBundleProductView(viewModel: configurableProductViewModel)
                    }
                    .redacted(reason: viewModel.disabled ? .placeholder : [] )
                }

                HStack {
                    if let presentProductSelector {
                        Button(OrderForm.Localization.addProducts) {
                            presentProductSelector()
                        }
                        .id(addProductButton)
                        .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                        .buttonStyle(PlusButtonStyle())
                    } else if !ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
                        Button(OrderForm.Localization.addProducts) {
                            viewModel.toggleProductSelectorVisibility()
                        }
                        .id(addProductButton)
                        .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                        .buttonStyle(PlusButtonStyle())
                    }
                    scanProductButton
                        .renderedIf(presentationStyle != .sideBySide)
                }
                .renderedIf(viewModel.shouldShowAddProductsButton)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .padding()
            .if(viewModel.shouldShowAddProductsButton, transform: { $0.frame(minHeight: Layout.rowHeight) })
            .background(Color(.listForeground(modal: true)))
            .sheet(item: $viewModel.configurableScannedProductViewModel) { configurableScannedProductViewModel in
                ConfigurableBundleProductView(viewModel: configurableScannedProductViewModel)
            }
            .sheet(isPresented: Binding<Bool>(
                get: { viewModel.isProductSelectorPresented && !viewModel.sideBySideViewFeatureFlagEnabled },
                set: { newValue in
                    viewModel.isProductSelectorPresented = newValue
                }
            ), onDismiss: {
                scroll.scrollTo(addProductButton)
            }, content: {
                if let productSelectorViewModel = viewModel.productSelectorViewModel {
                    ProductSelectorNavigationView(
                        configuration: ProductSelectorView.Configuration.addProductToOrder(),
                        isPresented: $viewModel.isProductSelectorPresented,
                        viewModel: productSelectorViewModel)
                    .onDisappear {
                        navigationButtonID = UUID()
                    }
                    .sheet(item: $viewModel.productToConfigureViewModel) { viewModel in
                        ConfigurableBundleProductView(viewModel: viewModel)
                    }
                }
            })
            .actionSheet(isPresented: $showPermissionsSheet, content: {
                ActionSheet(
                    title: Text(OrderForm.Localization.permissionsTitle),
                    message: Text(OrderForm.Localization.permissionsMessage),
                     buttons: [
                        .default(Text(OrderForm.Localization.permissionsOpenSettings), action: {
                            openSettingsAction()
                         }),
                         .cancel()
                     ]
                 )
            })
        }
    }
}

private extension ProductsSection {
    // Handles the different outcomes of barcode scanner presentation, depending on capture permission status
    func handleProductScannerPresentation() {
        viewModel.trackBarcodeScanningButtonTapped()
        let capturePermissionStatus = viewModel.capturePermissionStatus
        switch capturePermissionStatus {
        case .notPermitted:
            viewModel.trackBarcodeScanningNotPermitted()
            logPermissionStatus(status: .notPermitted)
            self.showPermissionsSheet = true
        case .notDetermined:
            logPermissionStatus(status: .notDetermined)
            viewModel.requestCameraAccess(onCompletion: { isPermissionGranted in
                if isPermissionGranted {
                    showAddProductViaSKUScanner = true
                    logPermissionStatus(status: .permitted)
                }
            })
        case .permitted:
            showAddProductViaSKUScanner = true
            logPermissionStatus(status: .permitted)
        }
    }

    // View containing the scanner, ready for product SKU reading input
    func scannerViewContent() -> ProductSKUInputScannerView {
        ProductSKUInputScannerView(onBarcodeScanned: { detectedBarcode in
            showAddProductViaSKUScanner = false
            showAddProductViaSKUScannerLoading = true
            viewModel.addScannedProductToOrder(barcode: detectedBarcode, onCompletion: { _ in
                showAddProductViaSKUScannerLoading = false
            }, onRetryRequested: {
                showAddProductViaSKUScanner = true
            })
        })
    }

    @ViewBuilder var scanProductRow: some View {
        Button(action: {
            handleProductScannerPresentation()
        }, label: {
            if showAddProductViaSKUScannerLoading {
                ProgressView()
            } else {
                HStack() {
                    Image(uiImage: .scanImage.withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: Layout.scanImageSize * scale)
                    Text(Localization.scanProductRowTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(Color(.accent))
                .bodyStyle()
            }
        })
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showAddProductViaSKUScanner, onDismiss: {
            scroll.scrollTo(addProductViaSKUScannerButton)
        }, content: {
            scannerViewContent()
        })
    }

    @ViewBuilder var scanProductButton: some View {
        Button(action: {
            handleProductScannerPresentation()
        }, label: {
            if showAddProductViaSKUScannerLoading {
                ProgressView()
            } else {
                Image(uiImage: .scanImage.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.scanImageSize * scale)
            }
        })
        .accessibilityLabel(OrderForm.Localization.scanProductButtonAccessibilityLabel)
        .sheet(isPresented: $showAddProductViaSKUScanner, onDismiss: {
            scroll.scrollTo(addProductViaSKUScannerButton)
        }, content: {
            scannerViewContent()
        })
    }
}

// MARK: Constants
private extension OrderForm {
    enum Layout {
        static let sectionSpacing: CGFloat = 8.0
        static let verticalSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
        static let storedTaxRateBottomSheetTopSpace: CGFloat = 24.0
        static let storedTaxRateBottomSheetRowCornerRadius: CGFloat = 8.0
        static let storedTaxRateBottomSheetStoredTaxRateCornerRadius: CGFloat = 8.0
        static let storedTaxRateBottomSheetButtonIconSize: CGFloat = 24.0
        static let productsHeaderButtonsSpacing: CGFloat = 20
        static let dividerLeadingPadding: CGFloat = 16
    }

    enum Localization {
        static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the Order screen")
        static let doneButton = NSLocalizedString("Done", comment: "Button to dismiss the Order Editing screen")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button to cancel the creation of an order on the New Order screen")
        static let collectPaymentButton = NSLocalizedString(
            "orderForm.payment.collect.button.title",
            value: "Collect Payment",
            comment: "Title of the primary button on the new order screen to collect payment, likely in-person. " +
            "This button first creates the order, then presents a view for the merchant to choose a payment method.")
        static let recalculateButton = NSLocalizedString(
            "orderForm.recalculate.button.title",
            value: "Recalculate",
            comment: "Title of the primary button on the new order screen when changes need to be manually synced. " +
            "Tapping the button will send changes to the server, and when complete the totals and taxes will be accurate.")
        static let products = NSLocalizedString("Products", comment: "Title text of the section that shows the Products when creating or editing an order")
        static let addProducts = NSLocalizedString("Add Products",
                                                   comment: "Title text of the button that allows to add multiple products when creating or editing an order")
        static let productRowAccessibilityHint = NSLocalizedString("Opens product detail.",
                                                                   comment: "Accessibility hint for selecting a product in an order form")
        static let permissionsTitle =
        NSLocalizedString("Camera permissions", comment: "Title of the action sheet button that links to settings for camera access")
        static let permissionsMessage = NSLocalizedString("Camera access is required for SKU scanning. " +
                                                          "Please enable camera permissions in your device settings",
                                                          comment: "Message of the action sheet button that links to settings for camera access")
        static let permissionsOpenSettings = NSLocalizedString("Open Settings", comment: "Button title to open device settings in an action sheet")
        static let storedTaxRateBottomSheetTitle = NSLocalizedString("Automatically adding tax rate",
                                                                     comment: "Title for the bottom sheet when there is a tax rate stored")
        static let storedTaxRateBottomSheetNewTaxRateButtonTitle = NSLocalizedString("Set a new tax rate for this order",
                                                                                     comment: "Title for the button to add a new tax rate" +
                                                                                     "when there is a tax rate stored")
        static let storedTaxRateBottomSheetClearTaxRateButtonTitle = NSLocalizedString("Clear address and stop using this rate",
                                                                                       comment: "Title for the button to clear the stored tax rate")
        static let scanProductButtonAccessibilityLabel = NSLocalizedString(
            "orderForm.products.add.scan.button.accessibilityLabel",
            value: "Scan barcode",
            comment: "Accessibility label for the barcode scanning button to add product")

        static let addProductButtonAccessibilityLabel = NSLocalizedString(
            "orderForm.products.add.button.accessibilityLabel",
            value: "Add product",
            comment: "Accessibility label for the + button to add product using a form")


        static let orderTotal = NSLocalizedString("Order total", comment: "Label for the the row showing the total cost of the order")
    }

    enum Accessibility {
        static let createButtonIdentifier = "new-order-create-button"
        static let cancelButtonIdentifier = "new-order-cancel-button"
        static let recalculateButtonIdentifier = "new-order-recalculate-button"
        static let doneButtonIdentifier = "edit-order-done-button"
        static let addProductButtonIdentifier = "new-order-add-product-button"
        static let addProductViaSKUScannerButtonIdentifier = "new-order-add-product-via-sku-scanner-button"
        static let orderFormScrollViewIdentifier = "order-form-scroll-view"
    }
}

struct OrderForm_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel(siteID: 123)

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel, presentProductSelector: nil)
        }
        .navigationViewStyle(StackNavigationViewStyle())

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel, presentProductSelector: nil)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel, presentProductSelector: nil)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel, presentProductSelector: nil)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .previewDisplayName("Right to left")
    }
}

private extension ProductSelectorView.Configuration {
    static func addProductToOrder() -> ProductSelectorView.Configuration {
        ProductSelectorView.Configuration(
            searchHeaderBackgroundColor: .listBackground,
            prefersLargeTitle: false,
            doneButtonTitleSingularFormat: Localization.doneButtonSingular,
            doneButtonTitlePluralFormat: Localization.doneButtonPlural,
            title: Localization.title,
            cancelButtonTitle: Localization.close,
            productRowAccessibilityHint: Localization.productRowAccessibilityHint,
            variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)
    }

    static func splitViewAddProductToOrder() -> ProductSelectorView.Configuration {
        ProductSelectorView.Configuration(
            productHeaderTextEnabled: true,
            searchHeaderBackgroundColor: .listBackground,
            prefersLargeTitle: false,
            doneButtonTitleSingularFormat: "",
            doneButtonTitlePluralFormat: "",
            title: Localization.title,
            cancelButtonTitle: nil,
            productRowAccessibilityHint: Localization.productRowAccessibilityHint,
            variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)
    }

    enum Localization {
        static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
        static let doneButtonSingular = NSLocalizedString("1 Product Selected",
                                                          comment: "Title of the action button at the bottom of the Select Products screen " +
                                                          "when one product is selected")
        static let doneButtonPlural = NSLocalizedString("%1$d Products Selected",
                                                        comment: "Title of the action button at the bottom of the Select Products screen " +
                                                        "when more than 1 item is selected, reads like: 5 Products Selected")
        static let productRowAccessibilityHint = NSLocalizedString("Adds product to order.",
                                                                   comment: "Accessibility hint for selecting a product in the Add Product screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Add Product screen"
        )
    }
}

private extension ProductsSection {
    enum Layout {
        static let rowHeight: CGFloat = 56.0
        static let scanImageSize: CGFloat = 24
    }

    enum Localization {
        static let scanProductRowTitle = NSLocalizedString(
            "orderForm.products.add.scan.row.title",
            value: "Scan Product",
            comment: "Title for the barcode scanning button to add a product to an order")
    }

    func openSettingsAction() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }

    func logPermissionStatus(status: EditableOrderViewModel.CapturePermissionStatus) {
        DDLogDebug("Capture permission status: \(status)")
    }
}

// MARK: - SKU scanning

private struct ProductSKUInputScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScannerContainerViewController

    let onBarcodeScanned: ((ScannedBarcode) -> Void)?

    func makeUIViewController(context: Context) -> ScannerContainerViewController {
        SKUCodeScannerProvider.SKUCodeScanner(onBarcodeScanned: { barcode in
            onBarcodeScanned?(barcode)
        })
    }

    func updateUIViewController(_ uiViewController: ScannerContainerViewController, context: Context) {
        // no-op
    }
}
