import SwiftUI
import Combine

/// Hosting controller that wraps an `OrderForm` view.
///
final class OrderFormHostingController: UIHostingController<OrderForm> {

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
        super.init(rootView: OrderForm(flow: flow, viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            // Set presentation delegate to track the user dismiss flow event
            if let navigationController = navigationController {
                navigationController.presentationController?.delegate = self
            } else {
                presentationController?.delegate = self
            }
        } else {
            handleSwipeBackGesture()
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

/// View to create or edit an order
///
struct OrderForm: View {
    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismissHandler: (() -> Void) = {}

    let flow: WooAnalyticsEvent.Orders.Flow

    @ObservedObject var viewModel: EditableOrderViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// Fix for breaking navbar button
    @State private var navigationButtonID = UUID()

    @State private var shouldShowNewTaxRateSelector = false
    @State private var shouldShowStoredTaxRateSheet = false

    @State private var shouldShowInformationalCouponTooltip = false

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scroll in
                ScrollView {
                    Group {
                        VStack(spacing: Layout.noSpacing) {

                            Group {
                                Divider() // Needed because `NonEditableOrderBanner` does not have a top divider
                                NonEditableOrderBanner(width: geometry.size.width)
                            }
                            .renderedIf(viewModel.shouldShowNonEditableIndicators)

                            OrderStatusSection(viewModel: viewModel, topDivider: !viewModel.shouldShowNonEditableIndicators)

                            Spacer(minLength: Layout.sectionSpacing)

                            ProductsSection(scroll: scroll,
                                            flow: flow,
                                            viewModel: viewModel, navigationButtonID: $navigationButtonID)
                                .disabled(viewModel.shouldShowNonEditableIndicators)

                            Group {
                                Divider()
                                Spacer(minLength: Layout.sectionSpacing)
                                Divider()
                            }
                            .renderedIf(viewModel.shouldSplitProductsAndCustomAmountsSections)

                            OrderCustomAmountsSection(viewModel: viewModel)
                                .disabled(viewModel.shouldShowNonEditableIndicators)

                            Divider()

                            Spacer(minLength: Layout.sectionSpacing)

                            Group {
                                if let title = viewModel.multipleLinesMessage {
                                    MultipleLinesMessage(title: title)
                                    Spacer(minLength: Layout.sectionSpacing)
                                }

                                OrderPaymentSection(
                                    viewModel: viewModel.paymentDataViewModel,
                                    shouldShowCouponsInfoTooltip: $shouldShowInformationalCouponTooltip)
                                    .disabled(viewModel.shouldShowNonEditableIndicators)
                            }

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

                            OrderCustomerSection(viewModel: viewModel, addressFormViewModel: viewModel.addressFormViewModel)

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
                .background(Color(.listBackground).ignoresSafeArea())
                .ignoresSafeArea(.container, edges: [.horizontal])
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
                        viewModel.createOrder()
                    }
                    .id(navigationButtonID)
                    .accessibilityIdentifier(Accessibility.createButtonIdentifier)
                    .disabled(viewModel.disabled)
                case .done:
                    Button(Localization.doneButton) {
                        viewModel.finishEditing()
                        dismissHandler()
                    }
                    .accessibilityIdentifier(Accessibility.doneButtonIdentifier)
                case .loading:
                    ProgressView()
                }
            }
        }
        .wooNavigationBarStyle()
        .onTapGesture {
            shouldShowInformationalCouponTooltip = false
        }
        .notice($viewModel.autodismissableNotice)
        .notice($viewModel.fixedNotice, autoDismiss: false)
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
}

/// Represents an information message to indicate about multiple shipping or fee lines.
///
private struct MultipleLinesMessage: View {

    /// Message to display.
    ///
    let title: String

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: OrderForm.Layout.noSpacing) {
            Divider()

            HStack(spacing: OrderForm.Layout.sectionSpacing) {

                Image(uiImage: .infoImage)
                    .foregroundColor(Color(.brand))

                Text(title)
                    .bodyStyle()
            }
            .padding()
            .padding(.horizontal, insets: safeAreaInsets)

            Divider()
        }
        .background(Color(.listForeground(modal: true)))
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

    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

    /// Fix for breaking navbar button
    @Binding var navigationButtonID: UUID

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

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: OrderForm.Layout.verticalSpacing) {
                HStack {
                    Text(OrderForm.Localization.products)
                        .accessibilityAddTraits(.isHeader)
                        .headlineStyle()

                    Spacer()

                    Image(uiImage: .lockImage)
                        .foregroundColor(Color(.brand))
                        .renderedIf(viewModel.shouldShowNonEditableIndicators)

                    HStack(spacing: OrderForm.Layout.productsHeaderButtonsSpacing) {
                        scanProductButton
                        .renderedIf(viewModel.isAddProductToOrderViaSKUScannerEnabled)

                        Button(action: {
                            viewModel.toggleProductSelectorVisibility()
                        }) {
                            Image(uiImage: .plusImage)
                        }
                        .accessibilityLabel(OrderForm.Localization.addProductButtonAccessibilityLabel)
                        .id(addProductButton)
                        .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                    }
                    .scaledToFit()
                    .renderedIf(!viewModel.shouldShowNonEditableIndicators)
                }
                .renderedIf(viewModel.shouldShowProductsSectionHeader)

                ForEach(viewModel.productRows) { productRow in
                    CollapsibleProductCard(viewModel: productRow,
                                           flow: flow,
                                           isLoading: viewModel.paymentDataViewModel.isLoading,
                                           shouldDisableDiscountEditing: viewModel.paymentDataViewModel.isLoading,
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
                    Button(OrderForm.Localization.addProducts) {
                        viewModel.toggleProductSelectorVisibility()
                    }
                    .id(addProductButton)
                    .accessibilityIdentifier(OrderForm.Accessibility.addProductButtonIdentifier)
                    .buttonStyle(PlusButtonStyle())

                    scanProductButton
                    .renderedIf(viewModel.isAddProductToOrderViaSKUScannerEnabled)
                }
                .renderedIf(viewModel.shouldShowAddProductsButton)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .padding()
            .background(Color(.listForeground(modal: true)))
            .sheet(isPresented: $viewModel.isProductSelectorPresented, onDismiss: {
                scroll.scrollTo(addProductButton)
            }, content: {
                if let productSelectorViewModel = viewModel.productSelectorViewModel {
                    ProductSelectorNavigationView(
                        configuration: ProductSelectorView.Configuration.addProductToOrder(),
                        source: .orderForm(flow: flow),
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
    var scanProductButton: some View {
        Button(action: {
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
        }, label: {
            if showAddProductViaSKUScannerLoading {
                ProgressView()
            } else {
                Image(uiImage: .scanImage.withRenderingMode(.alwaysTemplate))
                .foregroundColor(Color(.brand))
            }
        })
        .accessibilityLabel(OrderForm.Localization.scanProductButtonAccessibilityLabel)
        .sheet(isPresented: $showAddProductViaSKUScanner, onDismiss: {
            scroll.scrollTo(addProductViaSKUScannerButton)
        }, content: {
            ProductSKUInputScannerView(onBarcodeScanned: { detectedBarcode in
                showAddProductViaSKUScanner = false
                showAddProductViaSKUScannerLoading = true
                viewModel.addScannedProductToOrder(barcode: detectedBarcode, onCompletion: { _ in
                    showAddProductViaSKUScannerLoading = false
                }, onRetryRequested: {
                    showAddProductViaSKUScanner = true
                })
            })
        })
    }
}

// MARK: Constants
private extension OrderForm {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let verticalSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
        static let storedTaxRateBottomSheetTopSpace: CGFloat = 24.0
        static let storedTaxRateBottomSheetRowCornerRadius: CGFloat = 8.0
        static let storedTaxRateBottomSheetStoredTaxRateCornerRadius: CGFloat = 8.0
        static let storedTaxRateBottomSheetButtonIconSize: CGFloat = 24.0
        static let productsHeaderButtonsSpacing: CGFloat = 20
    }

    enum Localization {
        static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the Order screen")
        static let doneButton = NSLocalizedString("Done", comment: "Button to dismiss the Order Editing screen")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button to cancel the creation of an order on the New Order screen")
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
    }

    enum Accessibility {
        static let createButtonIdentifier = "new-order-create-button"
        static let cancelButtonIdentifier = "new-order-cancel-button"
        static let doneButtonIdentifier = "edit-order-done-button"
        static let addProductButtonIdentifier = "new-order-add-product-button"
        static let addProductViaSKUScannerButtonIdentifier = "new-order-add-product-via-sku-scanner-button"
    }
}

struct OrderForm_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel(siteID: 123)

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel)
        }

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            OrderForm(flow: .creation, viewModel: viewModel)
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
    typealias UIViewControllerType = ProductSKUInputScannerViewController

    let onBarcodeScanned: ((ScannedBarcode) -> Void)?

    func makeUIViewController(context: Context) -> ProductSKUInputScannerViewController {
        ProductSKUInputScannerViewController(onBarcodeScanned: { barcode in
            onBarcodeScanned?(barcode)
        })
    }

    func updateUIViewController(_ uiViewController: ProductSKUInputScannerViewController, context: Context) {
        // no-op
    }
}
