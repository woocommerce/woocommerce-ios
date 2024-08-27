import Yosemite
import Combine
import protocol Storage.StorageManagerType
import Experiments
import WooFoundation
import enum Networking.DotcomError

/// Encapsulates the item type an order can have, products or variations
///
typealias OrderBaseItem = SKUSearchResult

/// View model used in Order Creation and Editing flows.
///
final class EditableOrderViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let featureFlagService: FeatureFlagService
    private let permissionChecker: CaptureDevicePermissionChecker

    @Published var syncRequired: Bool = false

    // MARK: - Product selector states
    @Published var productSelectorViewModel: ProductSelectorViewModel?

    /// The source of truth of whether the product selector is presented.
    /// This can be triggered by different CTAs like in the order form and close CTA in the product selector.
    @Published var isProductSelectorPresented: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    enum Flow: Equatable {
        case creation
        case editing(initialOrder: Order)

        var analyticsFlow: WooAnalyticsEvent.Orders.Flow {
            switch self {
            case .creation:
                return .creation
            case .editing:
                return .editing
            }
        }
    }

    /// Encapsulates the type of screen that should be shown when navigating to Customer Details
    ///
    enum CustomerNavigationScreen {
        case form
        case selector
    }

    enum TaxRateRowAction {
        case taxSelector
        case storedTaxRateSheet
    }

    /// Current flow. For editing stores existing order state prior to applying any edits.
    ///
    let flow: Flow

    /// Indicates whether user has made any changes
    ///
    var hasChanges: Bool {
        switch flow {
        case .creation:
            return orderSynchronizer.order != OrderFactory.emptyNewOrder
        case .editing(let initialOrder):
            return orderSynchronizer.order != initialOrder
        }
    }

    /// Indicates whether view can be dismissed.
    ///
    var canBeDismissed: Bool {
        switch flow {
        case .creation: // Creation can be dismissed when there aren't changes pending to commit.
            return !hasChanges
        case .editing: // Editing can always be dismissed because changes are committed instantly.
            return true
        }
    }

    var sideBySideViewFeatureFlagEnabled: Bool {
        featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm)
    }

    /// Indicates whether the cancel button is visible.
    ///
    var shouldShowCancelButton: Bool {
        // The cancel button is handled by the AdaptiveModalContainer with the side-by-side view enabled, so this one should not be shown.
        guard !sideBySideViewFeatureFlagEnabled else {
            return false
        }
        return flow == .creation
    }

    /// Indicates the customer details screen to be shown. If there's no address added show the customer selector, otherwise the form so it can be edited
    ///
    var customerNavigationScreen: CustomerNavigationScreen {
        let shouldShowSelector = featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) &&
        // If there are no addresses added
        orderSynchronizer.order.billingAddress?.isEmpty ?? true &&
        orderSynchronizer.order.shippingAddress?.isEmpty ?? true

        return shouldShowSelector ? .selector : .form
    }

    var shouldShowSearchButtonInOrderAddressForm: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var enableAddingCustomAmountViaOrderTotalPercentage: Bool {
        orderSynchronizer.order.items.isNotEmpty || orderSynchronizer.order.fees.isNotEmpty
    }

    var title: String {
        switch flow {
        case .creation:
            return Localization.titleForNewOrder
        case .editing(let order):
            return String.localizedStringWithFormat(Localization.titleWithOrderNumber, order.number)
        }
    }

    /// Active navigation bar trailing item.
    /// Defaults to create button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem?

    @Published private(set) var doneButtonType: DoneButtonType = .done(loading: false)

    /// Tracks if a network request is being performed.
    ///
    @Published private(set) var performingNetworkRequest = false

    /// Defines the current notice that should be shown. It doesn't dismiss automatically
    /// Defaults to `nil`.
    ///
    @Published var fixedNotice: Notice?

    /// Defines the current notice that should be shown. Autodismissable
    /// Defaults to `nil`.
    ///
    @Published var autodismissableNotice: Notice?

    /// Optional view model for configurable a bundle product from the product selector.
    /// When the value is non-nil, the bundle product configuration screen is shown.
    @Published var productToConfigureViewModel: ConfigurableBundleProductViewModel?

    @Published private(set) var customAmountsSectionViewModel: OrderCustomAmountsSectionViewModel = .init()

    // MARK: Status properties

    /// Order creation date. For new order flow it's always current date.
    ///
    var dateString: String {
        switch flow {
            case .creation:
                let formatter = DateFormatter.mediumLengthLocalizedDateFormatter
                formatter.timeZone = .siteTimezone
                return formatter.string(from: Date())
            case .editing(let order):
                let formatter = DateFormatter.dateAndTimeFormatter
                formatter.timeZone = .siteTimezone
                return formatter.string(from: order.dateCreated)
        }
    }

    /// Representation of order status display properties.
    ///
    @Published private(set) var statusBadgeViewModel: StatusBadgeViewModel = .init(orderStatusEnum: .pending)

    /// Indicates if the order status list (selector) should be shown or not.
    ///
    @Published var shouldShowOrderStatusListSheet: Bool = false

    /// Defines if the view should be disabled.
    @Published private(set) var disabled: Bool = false

    @Published private(set) var collectPaymentDisabled: Bool = false

    /// Defines if the non editable indicators (banners, locks, fields) should be shown.
    @Published private(set) var shouldShowNonEditableIndicators: Bool = false

    /// Defines the tax based on setting to be displayed in the Taxes section.
    ///
    @Published private var taxBasedOnSetting: TaxBasedOnSetting?

    /// Selected tax rate to apply to the order
    ///
    @Published private var storedTaxRate: TaxRate? = nil

    /// Display the custom amount screen to edit it
    ///
    @Published var showEditCustomAmount: Bool = false

    /// Defines if the toggle to store the tax rate in the selector should be enabled by default
    ///
    var shouldStoreTaxRateInSelectorByDefault: Bool {
        storedTaxRate != nil
    }

    var taxRateRowAction: TaxRateRowAction {
        storedTaxRate == nil ? .taxSelector : .storedTaxRateSheet
    }

    /// Text to show on entry point for selecting a tax rate
    var taxRateRowText: String {
        storedTaxRate == nil ? Localization.setNewTaxRate : Localization.editTaxRateSetting
    }

    var storedTaxRateViewModel: TaxRateViewModel? {
        guard let storedTaxRate = storedTaxRate else { return nil }

        return TaxRateViewModel(taxRate: storedTaxRate, showChevron: false)
    }

    var editingFee: OrderFeeLine? = nil
    private var orderHasCoupons: Bool {
        orderSynchronizer.order.coupons.isNotEmpty
    }

    /// Whether product-discounts are disallowed for a given order
    /// Since coupons and discounts are mutually exclusive, if an order already has coupons then discounts should be disallowed.
    ///
    var shouldDisallowDiscounts: Bool {
        orderHasCoupons
    }

    /// If both products and custom amounts lists are empty we don't split their sections
    ///
    var shouldSplitProductsAndCustomAmountsSections: Bool {
        productRows.isNotEmpty || customAmountRows.isNotEmpty
    }

    var shouldSplitCustomerAndNoteSections: Bool {
        guard featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationCustomers) else {
            return customerDataViewModel.isDataAvailable || customerNoteDataViewModel.customerNote.isNotEmpty
        }
        return true
    }

    var shouldShowProductsSectionHeader: Bool {
        productRows.isNotEmpty
    }

    var shouldShowAddProductsButton: Bool {
        productRows.isEmpty
    }

    /// Whether gift card is supported in order form.
    ///
    @Published private var isGiftCardSupported: Bool = false

    @Published var selectionSyncApproach: OrderItemSelectionSyncApproach = .onSelectorButtonTap

    enum OrderItemSelectionSyncApproach {
        case immediate
        case onRecalculateButtonTap
        case onSelectorButtonTap
    }

    /// Status Results Controller.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        let resultsController = ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching order statuses: \(error)")
        }

        return resultsController
    }()

    /// Order statuses list
    ///
    private var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    // MARK: Products properties

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    /// Products list
    ///
    private var allProducts: Set<Product> = []

    /// Product Variations Results Controller.
    ///
    private lazy var productVariationsResultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    /// Product Variations list
    ///
    private var allProductVariations: Set<ProductVariation> = []

    /// View models for each product row in the order.
    ///
    @Published private(set) var productRows: [CollapsibleProductCardViewModel] = []

    /// View models for each custom amount in the order.
    ///
    @Published private(set) var customAmountRows: [CustomAmountRowViewModel] = []

    /// Selected product view model to render.
    /// Used to open the product details in `ProductDiscountViewModel`.
    ///
    @Published var discountViewModel: ProductDiscountViewModel? = nil

    /// Configurable bundle product view model to render.
    /// Used to open the bundle product configuration screen.
    ///
    @Published var configurableProductViewModel: ConfigurableBundleProductViewModel? = nil

    /// Configurable bundle product view model to render from a scanned bundle product.
    /// Used to open the bundle product configuration screen after scanning a bundle product either from the order form or order list.
    ///
    @Published var configurableScannedProductViewModel: ConfigurableBundleProductViewModel? = nil

    /// Whether the user can select a new tax rate.
    /// The User can change the tax rate by changing the customer address if:
    ///
    /// 1-. The 'Tax based on' setting is based on shipping or billing addresses.
    /// 2-. The initial stored tax rate finished applying.
    ///
    private var canChangeTaxRate = false

    /// Whether it should show the tax rate selector
    ///
    var shouldShowNewTaxRateSection: Bool {
        (orderSynchronizer.order.items.isNotEmpty || orderSynchronizer.order.fees.isNotEmpty) && canChangeTaxRate
    }

    /// Keeps track of selected/unselected Products, if any
    ///
    @Published private var selectedProducts: [Product] = []

    /// Keeps track of selected/unselected Product Variations, if any
    ///
    @Published private var selectedProductVariations: [ProductVariation] = []

    /// Keeps track of all selected Products and Product Variations IDs
    ///
    private var selectedProductsAndVariationsIDs: [Int64] {
        let selectedProductsCount = selectedProducts.compactMap { $0.productID }
        let selectedProductVariationsCount = selectedProductVariations.compactMap { $0.productVariationID }
        return selectedProductsCount + selectedProductVariationsCount
    }

    // MARK: Shipping line properties

    /// View model to display, add, edit, or remove shipping lines.
    ///
    @Published var shippingLineViewModel: EditableOrderShippingLineViewModel

    // MARK: Customer data properties

    /// View model for the customer section.
    ///
    @Published private(set) var customerSectionViewModel: OrderCustomerSectionViewModel

    /// Representation of customer data display properties.
    ///
    @Published private(set) var customerDataViewModel: CustomerDataViewModel = .init(billingAddress: nil, shippingAddress: nil)

    /// View model for the customer details address form.
    ///
    @Published private(set) var addressFormViewModel: CreateOrderAddressFormViewModel

    /// Keeps a reference to the latest Address form fields state
    ///
    @Published private(set) var latestAddressFormFields: AddressFormFields? = nil

    // MARK: Customer note properties

    /// Representation of customer note data display properties.
    ///
    @Published private(set) var customerNoteDataViewModel: CustomerNoteDataViewModel = .init(customerNote: "")

    /// View model for the customer note section.
    ///
    lazy private(set) var noteViewModel = { OrderFormCustomerNoteViewModel(originalNote: customerNoteDataViewModel.customerNote) }()

    // MARK: Payment properties

    /// Representation of payment data display properties
    ///
    @Published private(set) var paymentDataViewModel = PaymentDataViewModel()

    @Published private(set) var orderTotal: String = ""

    /// Saves a coupon line after an edition on it.
    ///
    /// - Parameter result: Contains the user action on the line: remove, add, or edit it changing the coupon code.
    ///
    func saveCouponLine(result: CouponLineDetailsResult) {
        switch result {
        case let .removed(removeCode):
            removeCoupon(with: removeCode)
        case let .added(newCode):
            addCoupon(with: newCode)
        case let .edited(oldCode, newCode):
            removeCoupon(with: oldCode)
            addCoupon(with: newCode)
        }
    }

    // MARK: -

    /// Defines the current order status.
    ///
    var currentOrderStatus: OrderStatusEnum {
        orderSynchronizer.order.status
    }

    /// Current OrderItems
    ///
    var currentOrderItems: [OrderItem] {
        orderSynchronizer.order.items
    }

    /// Keeps track of the list of bundle configurations by product ID from the product selector since bundle product
    /// is configured outside of the product selector.
    private var productSelectorBundleConfigurationsByProductID: [Int64: [[BundledProductConfiguration]]] = [:]

    /// Analytics engine.
    ///
    private let analytics: Analytics

    /// Order Synchronizer helper.
    ///
    private let orderSynchronizer: OrderSynchronizer

    /// Initial product or variation given to the order when is created, if any
    ///
    private let initialItem: OrderBaseItem?

    /// Initial customer data given to the order when it is created, if any
    ///
    private let initialCustomer: (id: Int64, billing: Address?, shipping: Address?)?

    private let orderDurationRecorder: OrderDurationRecorderProtocol

    private let barcodeSKUScannerItemFinder: BarcodeSKUScannerItemFinder

    private let quantityDebounceDuration: Double

    init(siteID: Int64,
         flow: Flow = .creation,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         initialItem: OrderBaseItem? = nil,
         initialCustomer: (id: Int64, billing: Address?, shipping: Address?)? = nil,
         quantityDebounceDuration: Double = Constants.quantityDebounceDuration) {
        self.siteID = siteID
        self.flow = flow
        self.stores = stores
        self.storageManager = storageManager
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
        self.orderSynchronizer = RemoteOrderSynchronizer(siteID: siteID, flow: flow, stores: stores, currencySettings: currencySettings)
        self.featureFlagService = featureFlagService
        self.orderDurationRecorder = orderDurationRecorder
        self.permissionChecker = permissionChecker
        self.initialItem = initialItem
        self.initialCustomer = initialCustomer
        self.barcodeSKUScannerItemFinder = BarcodeSKUScannerItemFinder(stores: stores)
        self.quantityDebounceDuration = quantityDebounceDuration

        // Set a temporary initial view model, as a workaround to avoid making it optional.
        // Needs to be reset before the view model is used.
        let addressFormViewModel = CreateOrderAddressFormViewModel(siteID: siteID,
                                                                   addressData: .init(billingAddress: nil, shippingAddress: nil),
                                                                   onAddressUpdate: nil)
        self.addressFormViewModel = addressFormViewModel

        // A temporary initial value is set here to avoid being an optional, and it will be reset in `configureCustomerDataViewModel`.
        self.customerSectionViewModel = .init(
            siteID: siteID,
            addressFormViewModel: addressFormViewModel,
            customerData: .init(customerID: nil,
                                email: nil,
                                fullName: nil,
                                billingAddressFormatted: nil,
                                shippingAddressFormatted: nil),
            isCustomerAccountRequired: false,
            isEditable: true,
            updateCustomer: { _ in },
            resetAddressForm: {}
        )

        self.shippingLineViewModel = EditableOrderShippingLineViewModel(siteID: siteID, flow: flow, orderSynchronizer: orderSynchronizer)

        configureDisabledState()
        configureCollectPaymentDisabledState()
        configureOrderTotal()
        configureNavigationTrailingItem()
        configureDoneButton()
        configureSyncErrors()
        configureStatusBadgeViewModel()
        configureProductRowViewModels()
        configureCustomAmountRowViewModels()
        configureCustomerDataViewModel()
        configurePaymentDataViewModel()
        configureCustomerNoteDataViewModel()
        configureNonEditableIndicators()
        resetAddressForm()
        syncInitialSelectedState()
        configureTaxRates()
        configureGiftCardSupport()
        observeGiftCardStatesForAnalytics()
        observeProductSelectorPresentationStateForViewModel()
        forwardSyncApproachToSynchronizer()
        observeChangesFromProductSelectorButtonTapSelectionSync()
        observeChangesInCustomerDetails()
    }

    /// Observes and keeps track of changes within the Customer Details
    ///
    private func observeChangesInCustomerDetails() {
        guard featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationCustomers) else {
            addressFormViewModel.fieldsPublisher.sink { [weak self] newValue in
                self?.latestAddressFormFields = newValue
            }
            .store(in: &cancellables)
            return
        }
        customerSectionViewModel.addressFormViewModel.fieldsPublisher.sink { [weak self] newValue in
            self?.latestAddressFormFields = newValue
        }
        .store(in: &cancellables)
    }

    /// Checks the latest Order sync, and returns the current items that are in the Order
    ///
    private func syncExistingSelectedProductsInOrder() -> [OrderItem] {
        var itemsInOrder: [OrderItem] = []
        let _ = orderSynchronizer.order.items.map { item in
            if item.variationID != 0 {
                if let _ = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
                    itemsInOrder.append(item)
                }
            } else {
                if let _ = allProducts.first(where: { $0.productID == item.productID }) {
                    itemsInOrder.append(item)
                }
            }
        }
        return itemsInOrder
    }

    /// Clears selected products and variations
    ///
    private func clearAllSelectedItems() {
        selectedProducts.removeAll()
        selectedProductVariations.removeAll()
        productSelectorBundleConfigurationsByProductID = [:]
    }

    private func trackClearAllSelectedItemsTapped() {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorClearSelectionButtonTapped(productType: .product))
    }

    /// Clears selected variations
    ///
    private func clearSelectedVariations() {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorClearSelectionButtonTapped(productType: .variation))
        selectedProductVariations.removeAll()
    }

    /// Toggles whether the product selector is shown or not.
    ///
    func toggleProductSelectorVisibility() {
        isProductSelectorPresented.toggle()
    }

    /// Synchronizes the item selection state by clearing all items, then retrieving the latest saved state
    ///
    func syncOrderItemSelectionStateOnDismiss() {
        clearAllSelectedItems()
        syncInitialSelectedState()
    }

    /// Sets `discountViewModel` based on the provided order item id.
    ///
    func setDiscountViewModel(_ itemID: Int64) {
        // Find order item based on the provided id.
        // Creates the product row view model needed for `ProductInOrderViewModel`.
        guard let orderItem = orderSynchronizer.order.items.first(where: { $0.itemID == itemID }),
              let rowViewModel = createProductRowViewModel(for: orderItem, childItems: []) else {
            return discountViewModel = nil
        }

        discountViewModel = .init(id: itemID,
                                  imageURL: rowViewModel.productRow.imageURL,
                                  name: rowViewModel.productRow.name,
                                  totalPricePreDiscount: orderItem.subtotal,
                                  priceSummary: rowViewModel.productRow.priceSummaryViewModel,
                                  discountConfiguration: addProductDiscountConfiguration(on: orderItem))
    }

    /// Removes an item from the order.
    ///
    /// - Parameter item: Item to remove from the order
    ///
    func removeItemFromOrder(_ item: OrderItem) {
        guard let input = createUpdateProductInput(item: item, quantity: 0) else { return }
        orderSynchronizer.setProduct.send(input)

        if item.variationID != 0 {
            selectedProductVariations.removeAll(where: { $0.productVariationID == item.variationID })
        } else if item.productID != 0 {
            selectedProducts.removeAll(where: { $0.productID == item.productID })
        }

        productSelectorViewModel?.removeSelection(id: item.productOrVariationID)

        // When synching changes immediately, we need to update variations as well.
        // If the variation list isn't showing, this will do nothing, but the model will still be accurate
        // the next time the variation list is opened.
        if let productVariationSelectorViewModel = productSelectorViewModel?.productVariationListViewModel {
            productVariationSelectorViewModel.removeSelection(item.productOrVariationID)
        }

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
    }

    /// Removes an item from the order.
    ///
    /// - Parameter productRowID: Item to remove from the order. Uses the unique ID of the product row.
    ///
    func removeItemFromOrder(_ productRowID: Int64) {
        guard let existingItemInOrder = currentOrderItems.first(where: { $0.itemID == productRowID }) else {
            return
        }
        removeItemFromOrder(existingItemInOrder)
    }

    func addDiscountToOrderItem(item: OrderItem, discount: Decimal) {
        guard let productInput = createUpdateProductInput(item: item, quantity: item.quantity, discount: discount) else {
            return
        }

        orderSynchronizer.setProduct.send(productInput)
    }

    /// Creates a view model for the `ProductRow` corresponding to an order item.
    ///
    func createProductRowViewModel(for item: OrderItem,
                                   childItems: [OrderItem] = [],
                                   isReadOnly: Bool = false,
                                   pricedIndividually: Bool = true) -> CollapsibleProductCardViewModel? {
        guard item.quantity > 0 else {
            // Don't render any item with `.zero` quantity.
            return nil
        }

        let itemDiscount = currentDiscount(on: item)
        let passingDiscountValue = itemDiscount > 0 ? itemDiscount : nil

        if item.variationID != 0,
            let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
            let variableProduct = allProducts.first(where: { $0.productID == item.productID })
            let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: variableProduct?.attributes ?? [])
            let stepperViewModel = ProductStepperViewModel(quantity: item.quantity,
                                                           name: item.name,
                                                           quantityUpdatedCallback: { [weak self] _ in
                guard let self else { return }
                self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductQuantityChange(flow: self.flow.analyticsFlow))
            }, removeProductIntent: { [weak self] in
                self?.removeItemFromOrder(item)
            })
            let rowViewModel = CollapsibleProductRowCardViewModel(id: item.itemID,
                                                                  productOrVariationID: variation.productVariationID,
                                                                  hasParentProduct: item.parent != nil,
                                                                  isReadOnly: isReadOnly,
                                                                  imageURL: variation.imageURL,
                                                                  name: item.name,
                                                                  sku: variation.sku,
                                                                  price: item.basePrice.stringValue,
                                                                  pricedIndividually: pricedIndividually,
                                                                  discount: passingDiscountValue,
                                                                  productTypeDescription: ProductType.variable.description,
                                                                  attributes: attributes,
                                                                  stockStatus: variation.stockStatus,
                                                                  stockQuantity: variation.stockQuantity,
                                                                  manageStock: variation.manageStock,
                                                                  stepperViewModel: stepperViewModel,
                                                                  analytics: analytics)
            return CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: [])
        } else if let product = allProducts.first(where: { $0.productID == item.productID }) {
            let childProductRows = childItems.compactMap { childItem in
                let pricedIndividually = {
                    guard product.productType == .bundle, let bundledItem = product.bundledItems.first(where: { $0.productID == childItem.productID }) else {
                        return true
                    }
                    return bundledItem.pricedIndividually
                }()
                let isReadOnly = product.productType == .bundle
                return createProductRowViewModel(for: childItem,
                                                 isReadOnly: isReadOnly,
                                                 pricedIndividually: pricedIndividually)
            }
            let stepperViewModel = ProductStepperViewModel(quantity: item.quantity,
                                                           name: item.name,
                                                           quantityUpdatedCallback: { [weak self] _ in
                guard let self else { return }
                self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductQuantityChange(flow: self.flow.analyticsFlow))
            }, removeProductIntent: { [weak self] in
                self?.removeItemFromOrder(item)
            })
            let isProductConfigurable = product.productType == .bundle && product.bundledItems.isNotEmpty

            let rowViewModel = CollapsibleProductRowCardViewModel(id: item.itemID,
                                                                  productOrVariationID: product.productID,
                                                                  hasParentProduct: item.parent != nil,
                                                                  isReadOnly: isReadOnly,
                                                                  isConfigurable: isProductConfigurable,
                                                                  productSubscriptionDetails: product.subscription,
                                                                  imageURL: product.imageURL,
                                                                  name: product.name,
                                                                  sku: product.sku,
                                                                  price: item.basePrice.stringValue,
                                                                  pricedIndividually: pricedIndividually,
                                                                  discount: passingDiscountValue,
                                                                  productTypeDescription: product.productType.description,
                                                                  attributes: [],
                                                                  stockStatus: product.productStockStatus,
                                                                  stockQuantity: product.stockQuantity,
                                                                  manageStock: product.manageStock,
                                                                  stepperViewModel: stepperViewModel,
                                                                  analytics: analytics,
                                                                  configure: { [weak self] in
                guard let self else { return }
                switch product.productType {
                    case .bundle:
                        self.configurableProductViewModel = .init(product: product,
                                                                  orderItem: item,
                                                                  childItems: childItems,
                                                                  onConfigure: { [weak self] configuration in
                            guard let self else { return }
                            self.addBundleConfigurationToOrderItem(item: item, bundleConfiguration: configuration)
                        })
                    default:
                        break
                }
            })
            return CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: childProductRows.map { $0.productRow })
        } else {
            DDLogInfo("No product or variation found. Couldn't create the product row")
            return nil
        }
    }

    /// Resets the view model for the customer details address form based on the order addresses.
    ///
    /// Can be used to configure the address form for first use or discard pending changes.
    ///
    func resetAddressForm() {
        guard featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationCustomers) else {
            addressFormViewModel = CreateOrderAddressFormViewModel(siteID: siteID,
                                                                   addressData: .init(billingAddress: orderSynchronizer.order.billingAddress,
                                                                                      shippingAddress: orderSynchronizer.order.shippingAddress),
                                                                   onAddressUpdate: { [weak self] updatedAddressData in
                let input = Self.createAddressesInputIfPossible(billingAddress: updatedAddressData.billingAddress,
                                                                shippingAddress: updatedAddressData.shippingAddress)
                self?.orderSynchronizer.setAddresses.send(input)
                self?.trackCustomerDetailsAdded()
            })
            // Since the form is recreated the original reference is lost. This is a problem if we update the form more than once
            // while keeping the Order open, since new published values won't be observed anymore.
            // This is resolved by hooking the publisher again to the new object
            observeChangesInCustomerDetails()
            return
        }

        customerSectionViewModel.addressFormViewModel = .init(siteID: siteID,
                                                              showEmailField: false,
                                                              addressData: .init(billingAddress: orderSynchronizer.order.billingAddress,
                                                                                 shippingAddress: orderSynchronizer.order.shippingAddress),
                                                              onAddressUpdate: { [weak self] updatedAddressData in
            let input = Self.createAddressesInputIfPossible(billingAddress: updatedAddressData.billingAddress,
                                                            shippingAddress: updatedAddressData.shippingAddress)
            self?.orderSynchronizer.setAddresses.send(input)
            self?.trackCustomerDetailsAdded()
        })
        // Since the form is recreated the original reference is lost. This is a problem if we update the form more than once
        // while keeping the Order open, since new published values won't be observed anymore.
        // This is resolved by hooking the publisher again to the new object
        observeChangesInCustomerDetails()
    }

    /// Saves the latest data entered in the Address Form Fields if the view is dismissed with unsaved changes
    /// Eg: on IPads, the modal is automatically dismissed on size class change, which would lead to data loss
    ///
    func saveInflightCustomerDetails() {
        guard let latestAddressFormFields else {
            return
        }
        let latestSyncBillingAddress = orderSynchronizer.order.billingAddress
        let latestSyncShippingAddress = orderSynchronizer.order.shippingAddress

        let latestAddressState = latestAddressFormFields.toAddress()

        if (latestSyncBillingAddress != latestAddressState) || (latestSyncShippingAddress != latestAddressState) {
            let address = Address(firstName: latestAddressFormFields.firstName,
                                  lastName: latestAddressFormFields.lastName,
                                  company: latestAddressFormFields.company,
                                  address1: latestAddressFormFields.address1,
                                  address2: latestAddressFormFields.address2,
                                  city: latestAddressFormFields.city,
                                  state: latestAddressFormFields.state,
                                  postcode: latestAddressFormFields.postcode,
                                  country: latestAddressFormFields.country,
                                  phone: latestAddressFormFields.phone,
                                  email: latestAddressFormFields.email)
            let input = Self.createAddressesInputIfPossible(billingAddress: address, shippingAddress: address)
            orderSynchronizer.setAddresses.send(input)
            trackCustomerDetailsAdded()
        }
    }

    func addCustomerAddressToOrder(customer: Customer) {
        let input = Self.createAddressesInputIfPossible(billingAddress: customer.billing, shippingAddress: customer.shipping)
        // The customer ID needs to be set before the addresses, so that the customer ID doesn't get overridden by the API response (customer_id = 0
        // by default) from updating the order's addresses remotely.
        orderSynchronizer.setCustomerID.send(customer.customerID)
        orderSynchronizer.setAddresses.send(input)
        resetAddressForm()
    }

    private func removeCustomerFromOrder() {
        orderSynchronizer.removeCustomerID.send(())
        let input = Self.createAddressesInputIfPossible(billingAddress: .empty, shippingAddress: .empty)
        orderSynchronizer.setAddresses.send(input)
    }

    func addTaxRateAddressToOrder(taxRate: TaxRate) {
        guard let taxBasedOnSetting = taxBasedOnSetting else {
            return
        }

        if storedTaxRate != taxRate {
            // If the new tax rate is different than the stored one forget the latter
            storedTaxRate = nil
        }

        let input: OrderSyncAddressesInput
        switch taxBasedOnSetting {
        case .customerBillingAddress:
            input = OrderSyncAddressesInput(billing: orderSynchronizer.order.billingAddress?.applyingTaxRate(taxRate: taxRate) ??
                                            Address.from(taxRate: taxRate),
                                            shipping: orderSynchronizer.order.shippingAddress)
        case .customerShippingAddress:
            input = OrderSyncAddressesInput(billing: orderSynchronizer.order.billingAddress,
                                            shipping: orderSynchronizer.order.shippingAddress?.applyingTaxRate(taxRate: taxRate) ??
                                            Address.from(taxRate: taxRate))
        default:
            // Do not add address if the taxes are not based on the customer's addresses
            return
        }

        orderSynchronizer.setAddresses.send(input)
        resetAddressForm()
        autodismissableNotice = Notice(title: Localization.newTaxRateSetSuccessMessage)
    }

    /// Updates the order creation draft with the current set customer note.
    ///
    func updateCustomerNote() {
        orderSynchronizer.setNote.send(noteViewModel.newNote)
        trackCustomerNoteAdded()
    }

    /// Saves the current contents of the Order Note, if there are differences with the latest edited content
    ///
    func saveInFlightOrderNotes() {
        let latestSyncedNote = orderSynchronizer.order.customerNote
        let currentlyEditedNote = noteViewModel.newNote

        if latestSyncedNote != currentlyEditedNote {
            updateCustomerNote()
        }
    }

    func orderTotalsExpansionChanged(expanded: Bool) {
        analytics.track(event: .Orders.orderTotalsExpansionChanged(flow: flow.analyticsFlow, expanded: expanded))
    }

    // MARK: - API Requests
    /// Creates an order remotely using the provided order details.
    ///
    private func createOrder(onSuccess: @escaping (_ order: Order, _ usesGiftCard: Bool) -> Void,
                             onFailure: @escaping (_ error: Error, _ usesGiftCard: Bool) -> Void) {
        performingNetworkRequest = true

        orderSynchronizer.commitAllChanges { [weak self] result, usesGiftCard in
            guard let self = self else { return }
            self.performingNetworkRequest = false

            switch result {
            case .success(let newOrder):
                onSuccess(newOrder, usesGiftCard)
            case .failure(let error):
                onFailure(error, usesGiftCard)
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
    }

    func collectPayment(for order: Order) {
        let formattedTotal = currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()

        let collectPaymentViewModel = PaymentMethodsViewModel(
            siteID: siteID,
            orderID: order.orderID,
            paymentLink: order.paymentURL,
            formattedTotal: formattedTotal,
            flow: .orderCreation)

        onFinishAndCollectPayment(order, collectPaymentViewModel)
    }

    /// Action triggered on `Done` button tap in order editing flow.
    ///
    func finishEditing() {
        self.onFinished(orderSynchronizer.order)
    }

    /// Assign this closure to be notified when the flow has finished.
    /// For creation it means that the order has been created.
    /// For edition it means that the merchant has finished editing the order.
    ///
    var onFinished: (Order) -> Void = { _ in }

    var onFinishAndCollectPayment: (Order, PaymentMethodsViewModel) -> Void = { _, _ in }

    /// Updates the order status & tracks its event
    ///
    func updateOrderStatus(newStatus: OrderStatusEnum) {
        let oldStatus = orderSynchronizer.order.status
        orderSynchronizer.setStatus.send(newStatus)
        analytics.track(event: WooAnalyticsEvent.Orders.orderStatusChange(flow: flow.analyticsFlow,
                                                                          orderID: orderSynchronizer.order.orderID,
                                                                          from: oldStatus,
                                                                          to: newStatus))
    }

    /// Deletes the order if it has been synced remotely, and removes it from local storage.
    ///
    func discardOrder() {
        // Only continue if the order has been synced remotely.
        guard orderSynchronizer.order.orderID != .zero else {
            return
        }

        let action = OrderAction.deleteOrder(siteID: siteID, order: orderSynchronizer.order, deletePermanently: true) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                DDLogError("⛔️ Error deleting new order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func onTaxRateSelected(_ taxRate: TaxRate) {
        addTaxRateAddressToOrder(taxRate: taxRate)
    }

    func onSetNewTaxRateTapped() {
        analytics.track(.orderCreationSetNewTaxRateTapped)
    }

    func onStoredTaxRateBottomSheetAppear() {
        analytics.track(.orderCreationStoredTaxRateBottomSheetAppear)
    }

    func onSetNewTaxRateFromBottomSheetTapped() {
        analytics.track(.orderCreationSetNewTaxRateFromBottomSheetTapped)
    }

    func onClearAddressFromBottomSheetTapped() {
        analytics.track(.orderCreationClearAddressFromBottomSheetTapped)
        forgetTaxRate()
    }

    func onDismissAddCustomAmountView() {
        editingFee = nil
    }

    func onAddCustomAmountButtonTapped() {
        analytics.track(.orderCreationAddCustomAmountTapped)
        addCustomAmount()
    }

    /// Starts the flow to add a custom amount.
    func addCustomAmount() {
        editingFee = nil
        enableAddingCustomAmountViaOrderTotalPercentage ?
        customAmountsSectionViewModel.showAddCustomAmountOptionsDialog.toggle() : customAmountsSectionViewModel.showAddCustomAmount.toggle()
    }

    func onCreateOrderTapped() {
        createOrder { [weak self] order, usesGiftCard in
            guard let self else { return }
            self.onFinished(order)
            self.trackCreateOrderSuccess(usesGiftCard: usesGiftCard)
        } onFailure: { [weak self] error, usesGiftCard in
            guard let self else { return }
            self.fixedNotice = NoticeFactory.createOrderErrorNotice(error, order: self.orderSynchronizer.order)
            self.trackCreateOrderFailure(usesGiftCard: usesGiftCard, error: error)
        }
        trackCreateButtonTapped()
    }

    func onCollectPaymentTapped() {
        createOrder { [weak self] order, usesGiftCard in
            guard let self else { return }
            self.collectPayment(for: order)
            self.trackCreateOrderSuccess(usesGiftCard: usesGiftCard)
        } onFailure: { [weak self] error, usesGiftCard in
            guard let self else { return }
            self.fixedNotice = NoticeFactory.createOrderErrorNotice(error, order: self.orderSynchronizer.order)
            self.trackCreateOrderFailure(usesGiftCard: usesGiftCard, error: error)
        }
        trackCollectPaymentTapped()
    }

    func onRecalculateTapped() {
        syncOrderItems(products: selectedProducts, variations: selectedProductVariations)
    }

    func addCustomAmountViewModel(with option: OrderCustomAmountsSection.ConfirmationOption?) -> AddCustomAmountViewModel {
        let viewModel = AddCustomAmountViewModel(inputType: addCustomAmountInputType(from: option ?? .fixedAmount),
                                                 onCustomAmountDeleted: { [weak self] feeID in
            self?.analytics.track(.orderCreationRemoveCustomAmountTapped)

            guard let match = self?.orderSynchronizer.order.fees.first(where: { $0.feeID == feeID}) else {
                DDLogError("Failed attempt to delete feeID \(String(describing: feeID))")
                return
            }
            self?.removeFee(match)
        },
                                                 onCustomAmountEntered: { [weak self] amount, name, feeID, isTaxable in
            let taxStatus: OrderFeeTaxStatus = isTaxable ? .taxable : .none
            if let feeID = feeID {
                self?.updateFee(with: feeID, total: amount, name: name, taxStatus: taxStatus)
            } else {
                self?.addFee(with: amount, name: name, taxStatus: taxStatus)
            }
        })

        if let editingFee {
            viewModel.preset(with: editingFee)
            self.editingFee = nil
        }

        return viewModel
    }
}

// MARK: - Types
extension EditableOrderViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case loading
        case recalculate
        case create
    }

    enum DoneButtonType: Equatable {
        case recalculate(loading: Bool)
        case create(loading: Bool)
        case done(loading: Bool)
    }

    /// Representation of order status display properties
    ///
    struct StatusBadgeViewModel {
        let title: String
        let color: UIColor

        init(orderStatus: OrderStatus) {
            title = orderStatus.name ?? orderStatus.slug
            color = {
                switch orderStatus.status {
                case .autoDraft, .pending, .cancelled, .refunded, .custom:
                    return .gray(.shade5)
                case .onHold:
                    return .withColorStudio(.orange, shade: .shade5)
                case .processing:
                    return .withColorStudio(.green, shade: .shade5)
                case .failed:
                    return .withColorStudio(.red, shade: .shade5)
                case .completed:
                    return .withColorStudio(.blue, shade: .shade5)
                }
            }()
        }

        init(orderStatusEnum: OrderStatusEnum) {
            let siteOrderStatus = OrderStatus(name: nil, siteID: 0, slug: orderStatusEnum.rawValue, total: 0)
            self.init(orderStatus: siteOrderStatus)
        }
    }

    /// Representation of customer data display properties
    ///
    struct CustomerDataViewModel {
        let isDataAvailable: Bool
        let fullName: String?
        let billingAddressFormatted: String?
        let shippingAddressFormatted: String?

        init(fullName: String? = nil,
             hasEmail: Bool = false,
             hasPhone: Bool = false,
             billingAddressFormatted: String? = nil,
             shippingAddressFormatted: String? = nil) {
            self.isDataAvailable = !fullName.isNilOrEmpty
                || hasEmail
                || hasPhone
                || !billingAddressFormatted.isNilOrEmpty
                || !shippingAddressFormatted.isNilOrEmpty
            self.fullName = fullName
            self.billingAddressFormatted = billingAddressFormatted
            self.shippingAddressFormatted = shippingAddressFormatted
        }

        init(billingAddress: Address?, shippingAddress: Address?) {
            let availableFullName = billingAddress?.fullName.isNotEmpty == true ? billingAddress?.fullName : shippingAddress?.fullName

            self.init(fullName: availableFullName?.isNotEmpty == true ? availableFullName : nil,
                      hasEmail: billingAddress?.hasEmailAddress == true,
                      hasPhone: billingAddress?.hasPhoneNumber == true || shippingAddress?.hasPhoneNumber == true,
                      billingAddressFormatted: billingAddress?.fullNameWithCompanyAndAddress,
                      shippingAddressFormatted: shippingAddress?.fullNameWithCompanyAndAddress)
        }
    }

    /// Representation of payment data display properties
    ///
    struct PaymentDataViewModel {
        /// Contains necessary info to render an applied gift card in the order form.
        struct AppliedGiftCard: Hashable {
            let code: String
            let amount: String
        }

        let siteID: Int64
        let shouldShowProductsTotal: Bool
        let itemsTotal: String
        let orderIsEmpty: Bool

        let shouldShowTotalCustomAmounts: Bool
        let customAmountsTotal: String

        let taxesTotal: String

        let couponLineViewModels: [CouponLineViewModel]
        let taxLineViewModels: [TaxLineViewModel]
        let taxEducationalDialogViewModel: TaxEducationalDialogViewModel
        let taxBasedOnSetting: TaxBasedOnSetting?
        let shouldShowTaxesInfoButton: Bool
        let shouldShowStoredTaxRateAddedAutomatically: Bool
        let couponCode: String
        var discountTotal: String
        let shouldShowDiscountTotal: Bool
        let shouldShowCoupon: Bool
        let shouldDisableAddingCoupons: Bool

        /// Enabled when gift cards plugin is active (woocommerce-gift-cards/woocommerce-gift-cards.php).
        let isGiftCardEnabled: Bool
        /// Whether the Add Gift Card CTA is enabled, when the order total is greater than zero.
        let isAddGiftCardActionEnabled: Bool
        /// Optional gift card code to apply to the order.
        let giftCardToApply: String?
        /// Gift cards that have been applied to the order.
        let appliedGiftCards: [AppliedGiftCard]

        /// Whether payment data is being reloaded (during remote sync)
        ///
        let isLoading: Bool

        let showNonEditableIndicators: Bool

        let addNewCouponLineClosure: (Coupon) -> Void
        let onGoToCouponsClosure: () -> Void
        let onTaxHelpButtonTappedClosure: () -> Void
        let onDismissWpAdminWebViewClosure: () -> Void
        let addGiftCardClosure: () -> Void
        let setGiftCardClosure: (_ code: String?) -> Void

        init(siteID: Int64 = 0,
             shouldShowProductsTotal: Bool = false,
             itemsTotal: String = "0",
             shouldShowTotalCustomAmounts: Bool = false,
             customAmountsTotal: String = "0",
             taxesTotal: String = "0",
             orderIsEmpty: Bool = false,
             shouldShowCoupon: Bool = false,
             shouldDisableAddingCoupons: Bool = false,
             couponLineViewModels: [CouponLineViewModel] = [],
             isGiftCardEnabled: Bool = false,
             isAddGiftCardActionEnabled: Bool = false,
             giftCardToApply: String? = nil,
             appliedGiftCards: [AppliedGiftCard] = [],
             taxBasedOnSetting: TaxBasedOnSetting? = nil,
             shouldShowTaxesInfoButton: Bool = false,
             shouldShowStoredTaxRateAddedAutomatically: Bool = false,
             taxLineViewModels: [TaxLineViewModel] = [],
             taxEducationalDialogViewModel: TaxEducationalDialogViewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: nil),
             couponCode: String = "",
             discountTotal: String = "",
             shouldShowDiscountTotal: Bool = false,
             isLoading: Bool = false,
             showNonEditableIndicators: Bool = false,
             addNewCouponLineClosure: @escaping (Coupon) -> Void = { _ in },
             onGoToCouponsClosure: @escaping () -> Void = {},
             onTaxHelpButtonTappedClosure: @escaping () -> Void = {},
             onDismissWpAdminWebViewClosure: @escaping () -> Void = {},
             addGiftCardClosure: @escaping () -> Void = {},
             setGiftCardClosure: @escaping (_ code: String?) -> Void = { _ in },
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
            self.siteID = siteID
            self.shouldShowProductsTotal = shouldShowProductsTotal
            self.itemsTotal = currencyFormatter.formatAmount(itemsTotal) ?? "0.00"
            self.shouldShowTotalCustomAmounts = shouldShowTotalCustomAmounts
            self.customAmountsTotal = currencyFormatter.formatAmount(customAmountsTotal) ?? "0.00"
            self.taxesTotal = currencyFormatter.formatAmount(taxesTotal) ?? "0.00"
            self.orderIsEmpty = orderIsEmpty
            self.isLoading = isLoading
            self.showNonEditableIndicators = showNonEditableIndicators
            self.shouldShowCoupon = shouldShowCoupon
            self.shouldDisableAddingCoupons = shouldDisableAddingCoupons
            self.couponLineViewModels = couponLineViewModels
            self.isGiftCardEnabled = isGiftCardEnabled
            self.isAddGiftCardActionEnabled = isAddGiftCardActionEnabled
            self.giftCardToApply = giftCardToApply
            self.appliedGiftCards = appliedGiftCards
            self.taxBasedOnSetting = taxBasedOnSetting
            self.shouldShowTaxesInfoButton = shouldShowTaxesInfoButton
            self.shouldShowStoredTaxRateAddedAutomatically = shouldShowStoredTaxRateAddedAutomatically
            self.taxLineViewModels = taxLineViewModels
            self.taxEducationalDialogViewModel = taxEducationalDialogViewModel
            self.couponCode = couponCode
            self.discountTotal = "-" + (currencyFormatter.formatAmount(discountTotal) ?? "0.00")
            self.shouldShowDiscountTotal = shouldShowDiscountTotal
            self.addNewCouponLineClosure = addNewCouponLineClosure
            self.onGoToCouponsClosure = onGoToCouponsClosure
            self.onTaxHelpButtonTappedClosure = onTaxHelpButtonTappedClosure
            self.onDismissWpAdminWebViewClosure = onDismissWpAdminWebViewClosure
            self.addGiftCardClosure = addGiftCardClosure
            self.setGiftCardClosure = setGiftCardClosure
        }

        /// Indicates whether the Coupons informational tooltip button should be shown
        /// The tooltip is rendered when an order has no coupons, but has product discounts.
        /// Since both are mutually exclusive but they are included in the Order's discounts total as one unique value, we cannot rely
        /// on `shouldShowCoupon` or `shouldShowDiscountTotal` alone for its visibility:
        ///
        var shouldRenderCouponsInfoTooltip: Bool {
            !shouldShowCoupon && shouldShowDiscountTotal
        }
    }

    /// Representation of order notes data display properties
    ///
    struct CustomerNoteDataViewModel {
        let customerNote: String
    }
}

// MARK: - Helpers
private extension EditableOrderViewModel {
    /// Converts the add custom amount UI input type to view models
    ///
    func addCustomAmountInputType(from option: OrderCustomAmountsSection.ConfirmationOption) -> AddCustomAmountViewModel.InputType {
        switch option {
        case .fixedAmount:
            return .fixedAmount
        case .orderTotalPercentage:
            let orderTotals = OrderTotalsCalculator(for: orderSynchronizer.order, using: self.currencyFormatter)
            return .orderTotalPercentage(baseAmount: orderTotals.orderTotal as Decimal)
        }
    }

    /// Sets the view to be `disabled` when `performingNetworkRequest` or when `statePublisher` is `.syncing(blocking: true)`
    ///
    func configureDisabledState() {
        Publishers.CombineLatest(orderSynchronizer.statePublisher, $performingNetworkRequest)
            .map { state, performingNetworkRequest -> Bool in
                switch (state, performingNetworkRequest) {
                case (.syncing(blocking: true), _),
                     (_, true):
                    return true
                default:
                    return false
                }
            }
            .assign(to: &$disabled)
    }

    func configureCollectPaymentDisabledState() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, $disabled)
            .map { [weak self] order, viewDisabled -> Bool in
                guard !viewDisabled else {
                    return true
                }
                let orderTotal = self?.currencyFormatter.convertToDecimal(order.total) as? Decimal ?? .zero
                return orderTotal <= .zero
            }
            .assign(to: &$collectPaymentDisabled)
    }

    func configureOrderTotal() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, Just("0.00"))
            .map { [weak self] order, defaultTotal -> String in
                return self?.currencyFormatter.formatAmount(order.total) ?? self?.currencyFormatter.formatAmount(defaultTotal) ?? ""
            }
            .assign(to: &$orderTotal)
    }

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func configureNavigationTrailingItem() {
        let requestInProgress = Publishers.CombineLatest(orderSynchronizer.statePublisher, $performingNetworkRequest)
            .map { syncState, performingNetworkRequest in
                if case .syncing = syncState {
                    return true
                } else {
                    return performingNetworkRequest
                }
            }

        Publishers.CombineLatest4($syncRequired, requestInProgress, $selectionSyncApproach, Just(flow))
            .map { syncRequired, performingNetworkRequest, syncApproach, flow -> NavigationItem? in
                guard !performingNetworkRequest else {
                    return .loading
                }

                switch flow {
                case .creation:
                    if syncRequired && syncApproach == .onRecalculateButtonTap {
                        return .recalculate
                    } else {
                        return .create
                    }
                case .editing:
                    return .none
                }
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Calculates what Call to Action button should be shown depending on our internal state.
    ///
    func configureDoneButton() {
        let requestInProgress = Publishers.CombineLatest(orderSynchronizer.statePublisher, $performingNetworkRequest)
            .map { syncState, performingNetworkRequest in
                if case .syncing = syncState {
                    return true
                } else {
                    return performingNetworkRequest
                }
            }

        Publishers.CombineLatest4($syncRequired, requestInProgress, $selectionSyncApproach, Just(flow))
            .map { syncRequired, requestInProgress, syncApproach, flow -> DoneButtonType in
                if syncRequired && syncApproach == .onRecalculateButtonTap {
                    return .recalculate(loading: requestInProgress)
                }

                switch flow {
                case .creation:
                    return .create(loading: requestInProgress)
                case .editing:
                    return .done(loading: requestInProgress)
                }
            }
            .assign(to: &$doneButtonType)
    }

    /// Updates the notice based on the `orderSynchronizer` sync state.
    ///
    func configureSyncErrors() {
        orderSynchronizer.statePublisher
            .map { [weak self] state in
                guard let self = self else { return nil }
                switch state {
                case let .error(error, usesGiftCard):
                    DDLogError("⛔️ Error syncing order remotely: \(error)")
                    self.trackSyncOrderFailure(usesGiftCard: usesGiftCard, error: error)
                    return NoticeFactory.syncOrderErrorNotice(error, flow: self.flow, with: self.orderSynchronizer)
                default:
                    return nil
                }
            }
            .assign(to: &$fixedNotice)
    }

    /// Updates status badge viewmodel based on status order property.
    ///
    func configureStatusBadgeViewModel() {
        orderSynchronizer.orderPublisher
            .map { [weak self] order in
                guard let siteOrderStatus = self?.currentSiteStatuses.first(where: { $0.status == order.status }) else {
                    return StatusBadgeViewModel(orderStatusEnum: order.status)
                }
                return StatusBadgeViewModel(orderStatus: siteOrderStatus)
            }
            .assign(to: &$statusBadgeViewModel)
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when adding multiple products to an Order
    /// - Parameters:
    ///   - products: Selected products
    ///   - variations: Selected product variations
    /// - Returns: [OrderSyncProductInput]
    ///
    func productInputAdditionsToSync(products: [Product], variations: [ProductVariation]) -> [OrderSyncProductInput] {
        var productInputs: [OrderSyncProductInput] = []
        var productVariationInputs: [OrderSyncProductInput] = []

        let itemsInOrder = syncExistingSelectedProductsInOrder()

        for product in products {
            // Only perform the operation if the product has not been already added to the existing Order
            if !itemsInOrder.contains(where: { $0.productID == product.productID && $0.parent == nil })
                || productSelectorBundleConfigurationsByProductID[product.productID]?.isNotEmpty == true {
                switch product.productType {
                    case .bundle:
                        if let bundleConfiguration = productSelectorBundleConfigurationsByProductID[product.productID]?.popFirst() {
                            productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1, bundleConfiguration: bundleConfiguration))
                        } else {
                            productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1))
                        }
                    default:
                        productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1))
                }
            }
        }
        productSelectorBundleConfigurationsByProductID = [:]

        for variation in variations {
            // Only perform the operation if the variation has not been already added to the existing Order
            if !itemsInOrder.contains(where: { $0.productOrVariationID == variation.productVariationID && $0.parent == nil }) {
                productVariationInputs.append(OrderSyncProductInput(product: .variation(variation), quantity: 1))
            }
        }

        return productInputs + productVariationInputs
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when removing multiple products from an Order
    /// - Parameters:
    ///   - products: Represents a Product entity
    ///   - variations: Represents a ProductVariation entity
    /// - Returns: [OrderSyncProductInput]
    ///
    func productInputDeletionsToSync(products: [Product?], variations: [ProductVariation?]) -> [OrderSyncProductInput] {
        var inputsToBeRemoved: [OrderSyncProductInput] = []

        let itemsInOrder = syncExistingSelectedProductsInOrder()

        // Products to be removed from the Order
        let removeProducts = itemsInOrder.filter { item in
            return item.variationID == 0 && !products.contains(where: { $0?.productID == item.productID }) && item.parent == nil
        }

        // Variations to be removed from the Order
        let removeProductVariations = itemsInOrder.filter { item in
            return item.variationID != 0 && !variations.contains(where: { $0?.productVariationID == item.variationID })
        }

        let allOrderItemsToBeRemoved = removeProducts + removeProductVariations

        for item in allOrderItemsToBeRemoved {

            if let input = createUpdateProductInput(item: item, quantity: 0) {
                inputsToBeRemoved.append(input)
            }

            analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
        }

        return inputsToBeRemoved

    }

    /// Adds, or removes multiple products from an Order
    ///
    func syncOrderItems(products: [Product], variations: [ProductVariation]) {
        // We need to send all OrderSyncProductInput in one call to the RemoteOrderSynchronizer, both additions and deletions
        // otherwise may ignore the subsequent values that are sent
        let addedItemsToSync = productInputAdditionsToSync(products: products, variations: variations)
        let removedItemsToSync = productInputDeletionsToSync(products: products, variations: variations)

        guard (addedItemsToSync + removedItemsToSync).isNotEmpty else {
            return
        }
        orderSynchronizer.setProducts.send(addedItemsToSync + removedItemsToSync)

        let productCount = addedItemsToSync.count - removedItemsToSync.count

        if addedItemsToSync.isNotEmpty {
            let includesBundleProductConfiguration = addedItemsToSync.contains(where: { $0.bundleConfiguration.isNotEmpty })
            analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: flow.analyticsFlow,
                                                                            source: .orderCreation,
                                                                            addedVia: .manually,
                                                                            productCount: productCount,
                                                                            includesBundleProductConfiguration: includesBundleProductConfiguration))
        }

        if removedItemsToSync.isNotEmpty {
            analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
        }

        syncRequired = false
    }

    /// Adds a selected product (from the product list) to the order.
    ///
    func changeSelectionStateForProduct(_ product: Product, to isSelected: Bool) {
        // Needed because `allProducts` is only updated at start, so product from new pages are not synced.
        allProducts.insert(product)

        if isSelected && !selectedProducts.contains(where: { $0.productID == product.productID }) {
            selectedProducts.append(product)
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemSelected(productType: .product))
        } else if !isSelected {
            selectedProducts.removeAll(where: { $0.productID == product.productID })
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemUnselected(productType: .product))
        }
    }

    /// Adds a selected product variation (from the product list) to the order.
    ///
    func changeSelectionStateForProductVariation(_ variation: ProductVariation, parent product: Product, to isSelected: Bool) {
        // Needed because `allProducts` is only updated at start, so product from new pages are not synced.
        allProducts.insert(product)
        allProductVariations.insert(variation)

        if isSelected && !selectedProductVariations.contains(where: { $0.productVariationID == variation.productVariationID }) {
            selectedProductVariations.append(variation)
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemSelected(productType: .variation))
        } else if !isSelected {
            selectedProductVariations.removeAll(where: { $0.productVariationID == variation.productVariationID })
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemUnselected(productType: .variation))
        }
    }

    /// Configures product row view models for each item in `orderDetails`.
    ///
    func configureProductRowViewModels() {
        updateLocalItemsReferences()
        orderSynchronizer.orderPublisher
            .map { $0.items }
            .removeDuplicates()
            .map { [weak self] items -> [CollapsibleProductCardViewModel] in
                guard let self = self else { return [] }
                return self.createProductRows(items: items)
            }
            .assign(to: &$productRows)
        configureOrderWithinitialItemIfNeeded()
    }

    func configureCustomAmountRowViewModels() {
        orderSynchronizer.orderPublisher
            .map { $0.fees }
            .removeDuplicates()
            .map { [weak self] fees -> [CustomAmountRowViewModel] in
                guard let self = self else { return [] }
                return fees.compactMap { fee in
                    guard !fee.isDeleted else { return nil }

                    return CustomAmountRowViewModel(id: fee.feeID,
                                                    name: fee.name ?? Localization.customAmountDefaultName,
                                                    total: self.currencyFormatter.formatAmount(fee.total) ?? "",
                                                    onEditCustomAmount: {
                        self.analytics.track(.orderCreationEditCustomAmountTapped)
                        self.editingFee = fee
                        self.showEditCustomAmount = true
                    })
                }
            }
            .assign(to: &$customAmountRows)
    }

    /// If given an initial product ID on initialization, updates the Order with the item
    ///
    func configureOrderWithinitialItemIfNeeded() {
        guard let item = initialItem else {
            return
        }

        updateOrderWithBaseItem(item)
    }

    /// Updates the Order with the given product from SKU scanning
    ///
    func updateOrderWithBaseItem(_ item: OrderBaseItem) {
        if case .product(let product) = item,
           product.variations.isNotEmpty {
            autodismissableNotice = Notice(title: Localization.parentProductScannedNoticeTitle,
                                           subtitle: Localization.parentProductScannedNoticeSubtitle)
            return
        }

        // When a scanned product is a bundle product, the bundle configuration view is shown first.
        if case let .product(product) = item, product.productType == .bundle {
            configurableScannedProductViewModel = .init(product: product,
                                                 orderItem: nil,
                                                 childItems: [],
                                                 onConfigure: { [weak self] configuration in
                guard let self else { return }
                self.saveBundleConfigurationFromProductSelector(product: product, bundleConfiguration: configuration)
                self.syncOrderItems(products: self.selectedProducts, variations: self.selectedProductVariations)
                self.configurableScannedProductViewModel = nil
            })
            return
        }

        guard currentOrderItems.contains(where: { $0.productOrVariationID == item.itemID }) else {
            // If it's not part of the current order, send the correct productType to the synchronizer
            switch item {
            case let .product(product):
                allProducts.insert(product)
                selectedProducts.append(product)
                orderSynchronizer.setProduct.send(.init(product: .product(product), quantity: 1))
            case let .variation(productVariation):
                allProductVariations.insert(productVariation)
                selectedProductVariations.append(productVariation)
                orderSynchronizer.setProduct.send(.init(product: .variation(productVariation), quantity: 1))
            }

            return
        }
        // Increase quantity if exists
        let match = productRows.first(where: { $0.productRow.productOrVariationID == item.itemID })
        match?.productRow.stepperViewModel.incrementQuantity()
    }

    /// If given initial customer data on initialization, updates the Order with the customer data.
    ///
    func configureOrderWithInitialCustomerIfNeeded(_ customerID: Int64?, billing: Address?, shipping: Address?) {
        guard let customerID else {
            return
        }
        orderSynchronizer.setCustomerID.send(customerID)
        orderSynchronizer.setAddresses.send(Self.createAddressesInputIfPossible(billingAddress: billing, shippingAddress: shipping))
        resetAddressForm()
    }

    /// Updates customer data viewmodel based on order addresses.
    ///
    func configureCustomerDataViewModel() {
        guard featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationCustomers) else {
            // Legacy customer section UI.
            orderSynchronizer.orderPublisher
                .map {
                    CustomerDataViewModel(billingAddress: $0.billingAddress, shippingAddress: $0.shippingAddress)
                }
                .assign(to: &$customerDataViewModel)
            configureOrderWithInitialCustomerIfNeeded(initialCustomer?.id, billing: initialCustomer?.billing, shipping: initialCustomer?.shipping)
            return
        }

        customerSectionViewModel = .init(
            siteID: siteID,
            addressFormViewModel: addressFormViewModel,
            customerData: .init(
                customerID: nil,
                email: nil,
                fullName: nil,
                billingAddressFormatted: nil,
                shippingAddressFormatted: nil
            ),
            isCustomerAccountRequired: false,
            isEditable: true,
            updateCustomer: { [weak self] customer in
                guard let self else { return }
                if let customer {
                    addCustomerAddressToOrder(customer: customer)
                } else {
                    removeCustomerFromOrder()
                }
            },
            resetAddressForm: resetAddressForm
        )

        orderSynchronizer.orderPublisher
            .map {
                CollapsibleCustomerCardViewModel.CustomerData(
                    customerID: $0.customerID,
                    email: $0.billingAddress?.email ?? $0.shippingAddress?.email,
                    fullName: $0.billingAddress?.fullName ?? $0.shippingAddress?.fullName,
                    billingAddressFormatted: $0.billingAddress?.formattedPostalAddress,
                    shippingAddressFormatted: $0.shippingAddress?.formattedPostalAddress
                )
            }
            .assign(to: &customerSectionViewModel.$customerData)

        configureOrderWithInitialCustomerIfNeeded(initialCustomer?.id, billing: initialCustomer?.billing, shipping: initialCustomer?.shipping)
    }

    /// Updates notes data viewmodel based on order customer notes.
    ///
    func configureCustomerNoteDataViewModel() {
        orderSynchronizer.orderPublisher
                .map {
                    CustomerNoteDataViewModel(customerNote: $0.customerNote ?? "")
                }
                .assign(to: &$customerNoteDataViewModel)
    }

    /// Updates payment section view model based on items in the order and order sync state.
    ///
    func configurePaymentDataViewModel() {
        Publishers.CombineLatest(Publishers.CombineLatest4(orderSynchronizer.orderPublisher,
                                                           orderSynchronizer.statePublisher,
                                                           $shouldShowNonEditableIndicators,
                                                           $taxBasedOnSetting),
                                 Publishers.CombineLatest(orderSynchronizer.giftCardToApplyPublisher,
                                                          $isGiftCardSupported))
            .map { [weak self] combinedPublisher, giftCardPublisher in
                let order = combinedPublisher.0
                let state = combinedPublisher.1
                let showNonEditableIndicators = combinedPublisher.2
                let taxBasedOnSetting = combinedPublisher.3
                let giftCardToApply = giftCardPublisher.0
                let isGiftCardEnabled = giftCardPublisher.1
                guard let self = self else {
                    return PaymentDataViewModel()
                }

                let orderTotals = OrderTotalsCalculator(for: order, using: self.currencyFormatter)

                let isDataSyncing: Bool = {
                    switch state {
                    case .syncing:
                        return true
                    default:
                        return false
                    }
                }()

                let appliedGiftCards: [PaymentDataViewModel.AppliedGiftCard] = {
                    order.appliedGiftCards.compactMap { giftCard in
                        let negativeAmount = -giftCard.amount
                        guard let formattedAmount = self.currencyFormatter.formatAmount(negativeAmount.description) else {
                            return nil
                        }
                        return .init(code: giftCard.code, amount: formattedAmount)
                    }
                }()

                let isAddGiftCardActionEnabled = currencyFormatter.convertToDecimal(order.total)?.compare(NSDecimalNumber.zero) == .orderedDescending
                let isDiscountBiggerThanZero = orderTotals.discountTotal.compare(NSDecimalNumber.zero) == .orderedDescending

                // The Order's `discountTotal` property accounts for both coupons and product discounts, but we need to know
                // where the discount comes from in order to allow/disallow coupons or discounts since these are mutually exclusive
                var disableCoupons: Bool {
                    // If coupons have already been applied to an order, allow more coupons to be applied
                    if order.coupons.isNotEmpty {
                        return false
                    }
                    // If an order is empty, disable coupons
                    if order.items.isEmpty {
                        return true
                    }
                    // If no coupons have been applied, but there are order discounts (discounts added directly to products of an order), disable coupons
                    if order.coupons.isEmpty && isDiscountBiggerThanZero {
                        return true
                    }
                    return false
                }

                return PaymentDataViewModel(siteID: self.siteID,
                                            shouldShowProductsTotal: order.items.isNotEmpty,
                                            itemsTotal: orderTotals.itemsTotal.stringValue,
                                            shouldShowTotalCustomAmounts: order.fees.filter { $0.name != nil }.isNotEmpty,
                                            customAmountsTotal: orderTotals.feesTotal.stringValue,
                                            taxesTotal: order.totalTax.isNotEmpty ? order.totalTax : "0",
                                            orderIsEmpty: order.isEmpty,
                                            shouldShowCoupon: order.coupons.isNotEmpty,
                                            shouldDisableAddingCoupons: disableCoupons,
                                            couponLineViewModels: self.couponLineViewModels(from: order.coupons),
                                            isGiftCardEnabled: isGiftCardEnabled,
                                            isAddGiftCardActionEnabled: isAddGiftCardActionEnabled,
                                            giftCardToApply: giftCardToApply,
                                            appliedGiftCards: appliedGiftCards,
                                            taxBasedOnSetting: taxBasedOnSetting,
                                            shouldShowTaxesInfoButton: order.isEditable,
                                            shouldShowStoredTaxRateAddedAutomatically: self.storedTaxRate != nil,
                                            taxLineViewModels: self.taxLineViewModels(from: order.taxes),
                                            taxEducationalDialogViewModel: TaxEducationalDialogViewModel(orderTaxLines: order.taxes,
                                                                                                         taxBasedOnSetting: taxBasedOnSetting),
                                            couponCode: order.coupons.first?.code ?? "",
                                            discountTotal: orderTotals.discountTotal.stringValue,
                                            shouldShowDiscountTotal: order.discountTotal.isNotEmpty && isDiscountBiggerThanZero,
                                            isLoading: isDataSyncing && !showNonEditableIndicators,
                                            showNonEditableIndicators: showNonEditableIndicators,
                                            addNewCouponLineClosure: { [weak self] coupon in
                                                self?.saveCouponLine(result: .added(newCode: coupon.code))
                                            },
                                            onGoToCouponsClosure: { [weak self] in
                                                self?.analytics.track(event: WooAnalyticsEvent.Orders.orderGoToCouponsButtonTapped())
                                            },
                                            onTaxHelpButtonTappedClosure: { [weak self] in
                                                self?.analytics.track(event: WooAnalyticsEvent.Orders.orderTaxHelpButtonTapped())
                                            },
                                            onDismissWpAdminWebViewClosure: { [weak self] in
                                                self?.configureTaxRates()
                                                self?.orderSynchronizer.retryTrigger.send()
                                            },
                                            addGiftCardClosure: { [weak self] in
                                                guard let self else { return }
                                                self.analytics.track(event: .Orders.orderFormAddGiftCardCTATapped(flow: self.flow.analyticsFlow))
                                            },
                                            setGiftCardClosure: { [weak self] code in
                                                guard let self else { return }
                                                self.orderSynchronizer.setGiftCard.send(code)
                                                self.analytics.track(event: .Orders.orderFormGiftCardSet(flow: self.flow.analyticsFlow,
                                                                                                         isRemoved: code == nil))
                                            },
                                            currencyFormatter: self.currencyFormatter)
            }
            .assign(to: &$paymentDataViewModel)
    }

    /// Binds the order state to the `shouldShowNonEditableIndicators` property.
    ///
    func configureNonEditableIndicators() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, Just(flow))
            .map { order, flow in
                switch flow {
                case .creation:
                    return false
                case .editing:
                    return !order.isEditable
                }
            }
            .assign(to: &$shouldShowNonEditableIndicators)
    }

    func configureTaxRates() {
        // Tax rates are not configurable if the order is not editable.
        // In the creation flow orders are initially (incorrectly) reported as not editable, so we have to check the flow here as well
        if case let .editing(order) = flow,
           !order.isEditable {
            return
        }

        stores.dispatch(SettingAction.retrieveTaxBasedOnSetting(siteID: siteID,
                                                                onCompletion: { [weak self] result in
            guard let self = self else { return }

            switch result {
                case .success(let setting):
                self.taxBasedOnSetting = setting

                let canApplyTaxRates = setting == .customerBillingAddress || setting == .customerShippingAddress
                if canApplyTaxRates {
                    Task { @MainActor in
                        if self.flow == .creation {
                            await self.applySelectedStoredTaxRateIfAny()
                        }

                        self.canChangeTaxRate = true
                    }
                }

                case .failure(let error):
                DDLogError("⛔️ Error retrieving tax based on setting: \(error)")
            }
        }))
    }

    func applySelectedStoredTaxRateIfAny() async {
        if let taxRate = await SelectedStoredTaxRateFetcher(stores: stores).fetchSelectedStoredTaxRate(siteID: siteID) {
            Task { @MainActor in
                addTaxRateAddressToOrder(taxRate: taxRate)
                storedTaxRate = taxRate
            }
        }
    }

    func configureGiftCardSupport() {
        Task { @MainActor in
            isGiftCardSupported = await checkIfGiftCardsPluginIsActive()
        }
    }

    @MainActor
    func checkIfGiftCardsPluginIsActive() async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.giftCardInOrderForm) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: SystemPluginPaths.giftCards) { plugin in
                continuation.resume(returning: plugin?.active == true)
            })
        }
    }

    func observeGiftCardStatesForAnalytics() {
        $paymentDataViewModel.filter { $0.isGiftCardEnabled && $0.isAddGiftCardActionEnabled }
            .first()
            .sink { [weak self] _ in
                guard let self else { return }
                self.analytics.track(event: .Orders.orderFormAddGiftCardCTAShown(flow: self.flow.analyticsFlow))
            }
            .store(in: &cancellables)
    }

    func observeProductSelectorPresentationStateForViewModel() {
        $isProductSelectorPresented
            .removeDuplicates()
            .map { [weak self] isPresented in
                guard let self,
                      isPresented else {
                    return nil
                }
                return ProductSelectorViewModel(
                    siteID: siteID,
                    source: .orderForm(flow: flow.analyticsFlow),
                    selectedItemIDs: selectedProductsAndVariationsIDs,
                    purchasableItemsOnly: true,
                    storageManager: storageManager,
                    stores: stores,
                    toggleAllVariationsOnSelection: false,
                    topProductsProvider: TopProductsFromCachedOrdersProvider(),
                    syncApproach: selectionSyncApproach.productSelectorSyncApproach,
                    orderSyncState: orderSynchronizer.statePublisher,
                    shouldShowNonEditableIndicators: shouldShowNonEditableIndicators,
                    externalNoticePublisher: $autodismissableNotice,
                    onProductSelectionStateChanged: { [weak self] product, isSelected in
                        guard let self else { return }
                        changeSelectionStateForProduct(product, to: isSelected)
                        evaluateSelectionSync()
                    },
                    onVariationSelectionStateChanged: { [weak self] variation, parentProduct, isSelected in
                        guard let self else { return }
                        changeSelectionStateForProductVariation(variation, parent: parentProduct, to: isSelected)
                        evaluateSelectionSync()
                    }, onMultipleSelectionCompleted: { [weak self] _ in
                        guard let self else { return }
                        syncOrderItems(products: self.selectedProducts, variations: self.selectedProductVariations)
                    }, onAllSelectionsCleared: { [weak self] in
                        guard let self else { return }
                        clearAllSelectedItems()
                        trackClearAllSelectedItemsTapped()
                        evaluateSelectionSync()
                    }, onSelectedVariationsCleared: { [weak self] in
                        guard let self else { return }
                        clearSelectedVariations()
                        evaluateSelectionSync()
                    }, onCloseButtonTapped: { [weak self] in
                        guard let self else { return }
                        syncOrderItemSelectionStateOnDismiss()
                        isProductSelectorPresented = false
                    }, onConfigureProductRow: { [weak self] product in
                        guard let self else { return }
                        productToConfigureViewModel = .init(product: product, orderItem: nil, childItems: [], onConfigure: { [weak self] configuration in
                            guard let self else { return }
                            saveBundleConfigurationFromProductSelector(product: product, bundleConfiguration: configuration)
                            productToConfigureViewModel = nil
                            evaluateSelectionSync()
                        })
                    })
            }
            .assign(to: &$productSelectorViewModel)
    }

    func evaluateSelectionSync() {
        guard sideBySideViewFeatureFlagEnabled else {
            return
        }
        switch selectionSyncApproach {
        case .immediate:
            syncOrderItems(products: selectedProducts, variations: selectedProductVariations)
        case .onRecalculateButtonTap:
            syncRequired = true
        case .onSelectorButtonTap:
            return
        }
    }

    func forwardSyncApproachToSynchronizer() {
        $selectionSyncApproach
            .sink { [weak self] selectionSyncApproach in
                guard let self,
                      sideBySideViewFeatureFlagEnabled else {
                    return
                }
                orderSynchronizer.updateBlockingBehavior(selectionSyncApproach == .immediate ? .allUpdates : .majorUpdates)
            }
            .store(in: &cancellables)
    }

    func observeChangesFromProductSelectorButtonTapSelectionSync() {
        $selectionSyncApproach
            .removeDuplicates()
            .sink { [weak self] selectionSyncApproach in
                guard let self,
                      sideBySideViewFeatureFlagEnabled else {
                    return
                }
                if selectionSyncApproach != .onSelectorButtonTap || syncRequired {
                    /// When we change from `onSelectorButtonTap`, we would lose unsynced changes if we do nothing.
                    /// `syncRequired` indicates that we have unsynced side-by-side changes, which would be lost when
                    /// moving to modal-on-modal.
                    syncOrderItems(products: selectedProducts, variations: selectedProductVariations)
                }
            }
            .store(in: &cancellables)
    }

    /// Tracks when customer details have been added
    ///
    func trackCustomerDetailsAdded() {
        guard customerDataViewModel.isDataAvailable else { return }
        let areAddressesDifferent: Bool = {
            guard let billingAddress = orderSynchronizer.order.billingAddress, let shippingAddress = orderSynchronizer.order.shippingAddress else {
                return false
            }
            return billingAddress != shippingAddress
        }()
        analytics.track(event: WooAnalyticsEvent.Orders.orderCustomerAdd(flow: flow.analyticsFlow, hasDifferentShippingDetails: areAddressesDifferent))
    }

    /// Tracks when customer note have been added
    ///
    func trackCustomerNoteAdded() {
        guard customerNoteDataViewModel.customerNote.isNotEmpty else { return }
        analytics.track(event: WooAnalyticsEvent.Orders.orderCustomerNoteAdd(flow: flow.analyticsFlow,
                                                                             orderID: orderSynchronizer.order.orderID,
                                                                             orderStatus: currentOrderStatus))
    }

    /// Tracks when the create order button is tapped.
    ///
    /// Warning: This methods assume that `orderSynchronizer.order.items.count` is equal to the product count,
    /// As the module evolves to handle more types of items, we need to update the property to something like `itemsCount`
    /// or figure out a better way to get the product count.
    ///
    func trackCreateButtonTapped() {
        let hasCustomerDetails = customerDataViewModel.isDataAvailable
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreateButtonTapped(
            order: orderSynchronizer.order,
            status: orderSynchronizer.order.status,
            productCount: orderSynchronizer.order.items.count,
            customAmountsCount: orderSynchronizer.order.fees.count,
            hasCustomerDetails: hasCustomerDetails,
            hasFees: orderSynchronizer.order.fees.isNotEmpty,
            hasShippingMethod: orderSynchronizer.order.shippingLines.isNotEmpty,
            products: Array(allProducts),
            horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
    }

    func trackCollectPaymentTapped() {
        let hasCustomerDetails = customerDataViewModel.isDataAvailable
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationCollectPaymentTapped(
            order: orderSynchronizer.order,
            status: orderSynchronizer.order.status,
            productCount: orderSynchronizer.order.items.count,
            customAmountsCount: orderSynchronizer.order.fees.count,
            hasCustomerDetails: hasCustomerDetails,
            hasFees: orderSynchronizer.order.fees.isNotEmpty,
            hasShippingMethod: orderSynchronizer.order.shippingLines.isNotEmpty,
            products: Array(allProducts),
            horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
    }

    /// Tracks an order creation success
    ///
    func trackCreateOrderSuccess(usesGiftCard: Bool) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationSuccess(millisecondsSinceSinceOrderAddNew:
                                                                                try? orderDurationRecorder.millisecondsSinceOrderAddNew(),
                                                                             couponsCount: Int64(orderSynchronizer.order.coupons.count),
                                                                             usesGiftCard: usesGiftCard,
                                                                             shippingLinesCount: Int64(orderSynchronizer.order.shippingLines.count)))
    }

    /// Tracks an order creation failure
    ///
    func trackCreateOrderFailure(usesGiftCard: Bool, error: Error) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationFailed(usesGiftCard: usesGiftCard,
                                                                            errorContext: String(describing: error),
                                                                            errorDescription: error.localizedDescription))
    }

    /// Tracks an order remote sync failure
    ///
    func trackSyncOrderFailure(usesGiftCard: Bool, error: Error) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderSyncFailed(flow: flow.analyticsFlow,
                                                                        usesGiftCard: usesGiftCard,
                                                                        errorContext: String(describing: error),
                                                                        errorDescription: error.localizedDescription))
    }

    /// Creates an `OrderSyncAddressesInput` type if the given data exists, otherwise returns nil
    ///
    static func createAddressesInputIfPossible(billingAddress: Address?, shippingAddress: Address?)  -> OrderSyncAddressesInput? {
        guard let billingAddress = billingAddress,
                let shippingAddress = shippingAddress else {
            return nil
        }

        return OrderSyncAddressesInput(billing: billingAddress, shipping: shippingAddress)
    }

    /// Creates a new `OrderSyncProductInput` type meant to update an existing input from `OrderSynchronizer`
    /// If the referenced product can't be found, `nil` is returned.
    ///
    private func createUpdateProductInput(item: OrderItem,
                                          childItems: [OrderItem] = [],
                                          quantity: Decimal,
                                          discount: Decimal? = nil,
                                          bundleConfiguration: [BundledProductConfiguration] = []) -> OrderSyncProductInput? {
        ProductInputTransformer.createUpdateProductInput(item: item,
                                                         childItems: childItems,
                                                         quantity: quantity,
                                                         discount: discount,
                                                         bundleConfiguration: bundleConfiguration,
                                                         allProducts: Array(allProducts),
                                                         allProductVariations: allProductVariations,
                                                         defaultDiscount: currentDiscount(on: item))
    }

    /// Creates the configuration related to adding a discount to a product. If the feature shouldn't be shown it returns `nil`
    ///
    func addProductDiscountConfiguration(on orderItem: OrderItem) -> ProductDiscountViewModel.DiscountConfiguration? {
        guard orderSynchronizer.order.coupons.isEmpty,
              case OrderSyncState.synced = orderSynchronizer.state,
              let subTotalDecimal = currencyFormatter.convertToDecimal(orderItem.subtotal) else {
            return nil
        }

        return .init(addedDiscount: currentDiscount(on: orderItem),
                     baseAmountForDiscountPercentage: subTotalDecimal as Decimal,
                     onSaveFormattedDiscount: { [weak self] formattedDiscount in
                        guard let formattedDiscount = formattedDiscount,
                              let discount = self?.currencyFormatter.convertToDecimal(formattedDiscount) else {
                            self?.addDiscountToOrderItem(item: orderItem, discount: 0)
                            return
                        }

                            self?.addDiscountToOrderItem(item: orderItem, discount: discount as Decimal)
                    })
    }

    /// Calculates the discount on an order item, that is, subtotal minus total
    ///
    func currentDiscount(on item: OrderItem) -> Decimal {
        guard let subtotal = currencyFormatter.convertToDecimal(item.subtotal),
              let total = currencyFormatter.convertToDecimal(item.total) else {
            return 0
        }

        return subtotal.subtracting(total) as Decimal
    }

    /// Creates `ProductRowViewModels` ready to be used as product rows.
    ///
    func createProductRows(items: [OrderItem]) -> [CollapsibleProductCardViewModel] {
        items.compactMap { item -> CollapsibleProductCardViewModel? in
            guard item.parent == nil else { // Don't create a separate product row for child items
                return nil
            }

            let childItems = items.filter { $0.parent == item.itemID }
            guard let productRowViewModel = self.createProductRowViewModel(for: item, childItems: childItems) else {
                return nil
            }

            // Observe changes to the product quantity
            productRowViewModel.productRow.stepperViewModel.$quantity
                .dropFirst() // Omit the default/initial quantity to prevent a double trigger.
                // The quantity can be incremented/decremented quickly, and the order sync can be blocking (e.g. with bundle configuration).
                // To avoid the UI being blocked for each quantity update, a debounce is added to wait for the final quantity
                // within a 0.5s time frame.
                .debounce(for: .seconds(quantityDebounceDuration), scheduler: DispatchQueue.main)
                .sink { [weak self] newQuantity in
                    guard let self else { return }
                    let childItems = items.filter { $0.parent == item.itemID }
                    guard let newInput = createUpdateProductInput(item: item, childItems: childItems, quantity: newQuantity) else {
                        return
                    }
                    self.orderSynchronizer.setProduct.send(newInput)
                }
                .store(in: &self.cancellables)

            return productRowViewModel
        }
    }

    func saveBundleConfigurationFromProductSelector(product: Product, bundleConfiguration: [BundledProductConfiguration]) {
        productSelectorBundleConfigurationsByProductID[product.productID] = (productSelectorBundleConfigurationsByProductID[product.productID] ?? [])
        + [bundleConfiguration]
        selectedProducts.append(product)
        productSelectorViewModel?.addSelection(id: product.productID)
    }

    func addBundleConfigurationToOrderItem(item: OrderItem, bundleConfiguration: [BundledProductConfiguration]) {
        guard let productInput = createUpdateProductInput(item: item, quantity: item.quantity, bundleConfiguration: bundleConfiguration) else {
            return
        }
        orderSynchronizer.setProduct.send(productInput)
    }
}

private extension EditableOrderViewModel.OrderItemSelectionSyncApproach {
    var productSelectorSyncApproach: ProductSelectorViewModel.SyncApproach {
        switch self {
        case .immediate, .onRecalculateButtonTap:
            return .external
        case .onSelectorButtonTap:
            return .onButtonTap
        }
    }
}

private extension EditableOrderViewModel {
    /// Fetches products from storage.
    ///
    func updateProductsResultsController() {
        do {
            try productsResultsController.performFetch()
            allProducts = Set(productsResultsController.fetchedObjects)
        } catch {
            DDLogError("⛔️ Error fetching products for order: \(error)")
        }
    }

    /// Fetches product variations from storage.
    ///
    func updateProductVariationsResultsController() {
        do {
            try productVariationsResultsController.performFetch()
            allProductVariations = Set(productVariationsResultsController.fetchedObjects)
        } catch {
            DDLogError("⛔️ Error fetching product variations for order: \(error)")
        }
    }

    func updateLocalItemsReferences() {
        updateProductsResultsController()
        updateProductVariationsResultsController()
    }

    /// Syncs initial selected state for all items in the Order
    ///
    func syncInitialSelectedState() {
        selectedProducts = []
        selectedProductVariations = []

        let _ = orderSynchronizer.order.items.map { item in
            if item.variationID != 0 {
                if let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID && item.parent == nil }) {
                    selectedProductVariations.append(variation)
                }
            } else {
                if let product = allProducts.first(where: { $0.productID == item.productID && item.parent == nil }) {
                    selectedProducts.append(product)
                }
            }
        }
    }

    /// Coupon Line view models
    /// - Parameter couponLines: order's coupon lines
    /// - Returns: View models for the coupon lines, including the view model for the details screen in case it's navigated to
    ///
    func couponLineViewModels(from couponLines: [OrderCouponLine]) -> [CouponLineViewModel] {
        couponLines.map {
            CouponLineViewModel(title: String.localizedStringWithFormat(Localization.CouponSummary.singular, $0.code),
                          discount: "-" + (currencyFormatter.formatAmount($0.discount) ?? "0.00"),
                          detailsViewModel: CouponLineDetailsViewModel(code: $0.code,
                                                                       siteID: siteID,
                                                                       didSelectSave: saveCouponLine))

        }
    }

    /// Tax Line view models
    /// - Parameter taxLines: order's coupon lines
    /// - Returns: View models for the tax lines
    ///
    func taxLineViewModels(from taxLines: [OrderTaxLine]) -> [TaxLineViewModel] {
        taxLines.map { TaxLineViewModel(title: "\($0.label) • \($0.ratePercent.percentFormatted() ?? "")",
                                        value: currencyFormatter.formatAmount($0.totalTax) ?? "0.00")
        }
    }

    func addCoupon(with code: String) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCouponAdd(flow: flow.analyticsFlow))
        orderSynchronizer.addCoupon.send(code)
    }

    func removeCoupon(with code: String) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCouponRemove(flow: flow.analyticsFlow))
        orderSynchronizer.removeCoupon.send(code)
    }

    func addFee(with total: String, name: String? = nil, taxStatus: OrderFeeTaxStatus) {
        let feeLine = OrderFactory.newOrderFee(total: total, name: name, taxStatus: taxStatus)
        orderSynchronizer.addFee.send(feeLine)
        analytics.track(event: WooAnalyticsEvent.Orders.orderFeeAdd(flow: flow.analyticsFlow, taxStatus: taxStatus.rawValue))
    }

    func updateFee(with id: Int64, total: String, name: String? = nil, taxStatus: OrderFeeTaxStatus) {
        guard let updatingFee = orderSynchronizer.order.fees.first(where: { $0.feeID == id }) else {
            return
        }

        let updatedFee = updatingFee.copy(name: name, taxStatus: taxStatus, total: total)
        orderSynchronizer.updateFee.send(updatedFee)
        analytics.track(event: WooAnalyticsEvent.Orders.orderFeeUpdate(flow: flow.analyticsFlow, taxStatus: taxStatus.rawValue))
    }

    func removeFee(_ fee: OrderFeeLine) {
        orderSynchronizer.removeFee.send(fee)
        analytics.track(event: WooAnalyticsEvent.Orders.orderFeeRemove(flow: flow.analyticsFlow))
    }

    /// Erases stored tax rate from order by cleaning the address, and removes stored tax rate from storage
    ///
    func forgetTaxRate() {
        let order = orderSynchronizer.order
        orderSynchronizer.setAddresses.send(OrderSyncAddressesInput(billing: order.billingAddress?.resettingTaxRateComponents(),
                                                                    shipping: order.shippingAddress?.resettingTaxRateComponents()))
        resetAddressForm()
        storedTaxRate = nil
        stores.dispatch(AppSettingsAction.setSelectedTaxRateID(id: nil, siteID: siteID))
        autodismissableNotice = Notice(title: Localization.stopAddingTaxRateAutomaticallySuccessMessage)
    }
}

// MARK: Camera scanner

extension EditableOrderViewModel {

    enum CapturePermissionStatus {
        case permitted
        case notPermitted
        case notDetermined
    }

    enum ScannerError: Error {
        case nilSKU
        case productNotFound
    }

    /// Returns the current app permission status to capture media
    ///
    var capturePermissionStatus: CapturePermissionStatus {
        let authStatus = permissionChecker.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
            return .permitted
        case .denied, .restricted:
            return .notPermitted
        default:
            return .notDetermined
        }
    }

    func requestCameraAccess(onCompletion: @escaping ((Bool) -> Void)) {
        permissionChecker.requestAccess(for: .video, completionHandler: onCompletion)
    }

    /// Attempts to add a Product to the current Order by SKU search
    ///
    func addScannedProductToOrder(barcode: ScannedBarcode, onCompletion: @escaping (Result<Void, Error>) -> Void, onRetryRequested: @escaping () -> Void) {
        analytics.track(event: WooAnalyticsEvent.BarcodeScanning.barcodeScanningSuccess(from: .orderCreation))
        mapScannedBarcodetoBaseItem(barcode: barcode) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(result):
                Task { @MainActor in
                    self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: self.flow.analyticsFlow,
                                                                                         source: .orderCreation,
                                                                                         addedVia: .scanning,
                                                                                         includesBundleProductConfiguration: false))
                    self.updateOrderWithBaseItem(result)
                    onCompletion(.success(()))
                }
            case let .failure(error):
                Task { @MainActor in
                    onCompletion(.failure(ScannerError.productNotFound))
                    self.autodismissableNotice = NoticeFactory.createProductNotFoundAfterSKUScanningErrorNotice(for: error,
                                                                                                                code: barcode,
                                                                                                                withRetryAction: { [weak self] in
                        self?.autodismissableNotice = nil
                        onRetryRequested()
                    })
                }
            }
        }
    }

    func trackBarcodeScanningButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.Orders.productAddNewFromBarcodeScanningTapped())
    }

    func trackBarcodeScanningNotPermitted() {
        analytics.track(event: WooAnalyticsEvent.BarcodeScanning.barcodeScanningFailure(from: .orderCreation, reason: .cameraAccessNotPermitted))
    }

    /// Attempts to map SKU to Product
    ///
    private func mapScannedBarcodetoBaseItem(barcode: ScannedBarcode, onCompletion: @escaping (Result<OrderBaseItem, Error>) -> Void) {
        Task {
            do {
                let result = try await barcodeSKUScannerItemFinder.searchBySKU(from: barcode, siteID: siteID, source: .orderCreation)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: Constants

extension EditableOrderViewModel {
    enum NoticeFactory {
        /// Returns a default order creation error notice.
        ///
        static func createOrderErrorNotice(_ error: Error, order: Order) -> Notice {
            guard !isEmailError(error, order: order) else {
                return Notice(title: Localization.invalidBillingParameters, message: Localization.invalidBillingSuggestion, feedbackType: .error)
            }

            if let giftCardErrorNotice = giftCardErrorNotice(from: error) {
                return giftCardErrorNotice
            }

            return Notice(title: Localization.errorMessageOrderCreation, feedbackType: .error)
        }

        static func createProductNotFoundAfterSKUScanningErrorNotice(for error: Error,
                                                                     code: ScannedBarcode,
                                                                     withRetryAction action: @escaping () -> Void) -> Notice {
            BarcodeSKUScannerErrorNoticeFactory.notice(for: error, code: code, actionHandler: action)
        }

        /// Returns an order sync error notice.
        ///
        static func syncOrderErrorNotice(_ error: Error, flow: Flow, with orderSynchronizer: OrderSynchronizer) -> Notice {
            guard !isEmailError(error, order: orderSynchronizer.order) else {
                return Notice(title: Localization.invalidBillingParameters, message: Localization.invalidBillingSuggestion, feedbackType: .error)
            }

            guard !isCouponsError(error) else {
                if let errorCouponCode = orderSynchronizer.order.coupons.last?.code {
                    orderSynchronizer.removeCoupon.send(errorCouponCode)
                }

                return Notice(title: Localization.couponsErrorNoticeTitle,
                              message: Localization.couponsErrorNoticeMessage,
                              feedbackType: .error,
                              actionTitle: Localization.dismissCouponErrorNotice) {
                        // Syncs the order without the failing coupon
                        orderSynchronizer.retryTrigger.send()
                }
            }

            if let giftCardErrorNotice = giftCardErrorNotice(from: error) {
                return giftCardErrorNotice
            }

            let errorMessage: String
            switch flow {
            case .creation:
                errorMessage = Localization.errorMessageNewOrderSync
            case .editing:
                errorMessage = Localization.errorMessageEditOrderSync
            }

            return Notice(title: errorMessage, feedbackType: .error, actionTitle: Localization.retryOrderSync) {
                orderSynchronizer.retryTrigger.send()
            }
        }

        /// Returns `true` if the provided error is about invalid shipping details and the latest order does not have a billing email.
        /// This is needed because old stores error when sending empty emails.
        ///
        private static func isEmailError(_ error: Error, order: Order) -> Bool {
            switch error as? DotcomError {
            case .unknown(code: "rest_invalid_param", let message?):
                return message.contains("billing") && order.billingAddress?.hasEmailAddress == false
            default:
                return false
            }
        }

        private static func isCouponsError(_ error: Error) -> Bool {
            if case .unknown(code: "woocommerce_rest_invalid_coupon", _) = error as? DotcomError {
                return true
            }

            return false
        }

        private static func giftCardErrorNotice(from error: Error) -> Notice? {
            guard let giftCardError = error as? OrderStore.GiftCardError else {
                return nil
            }
            return Notice(title: giftCardError.noticeTitle, message: giftCardError.noticeMessage, feedbackType: .error)
        }
    }
}

private extension OrderBaseItem {
    var itemID: Int64 {
        switch self {
        case let .product(product):
            return product.productID
        case let .variation(variation):
            return variation.productVariationID
        }
    }
}

private extension EditableOrderViewModel {
    enum Localization {
        static let titleForNewOrder = NSLocalizedString("New Order", comment: "Title for the order creation screen")
        static let titleWithOrderNumber = NSLocalizedString("Order #%1$@", comment: "Order number title. Parameters: %1$@ - order number")
        static let errorMessageOrderCreation = NSLocalizedString("Unable to create new order",
                                                                 comment: "Notice displayed when order creation fails")
        static let errorMessageNewOrderSync = NSLocalizedString("Unable to load taxes for order",
                                                                comment: "Notice displayed when data cannot be synced for new order")
        static let errorMessageEditOrderSync = NSLocalizedString("Unable to save changes. Please try again.",
                                                                 comment: "Notice displayed when data cannot be synced for edited order")

        static let retryOrderSync = NSLocalizedString("Retry", comment: "Action button to retry syncing the draft order")
        static let dismissCouponErrorNotice = NSLocalizedString("OK", comment: "Action button to dismiss the coupon error notice")

        static let invalidBillingParameters =
        NSLocalizedString("Unable to set customer details.",
                          comment: "Error notice title when we fail to update an address when creating or editing an order.")
        static let invalidBillingSuggestion =
        NSLocalizedString("Please make sure you are running the latest version of WooCommerce and try again later.",
                          comment: "Recovery suggestion when we fail to update an address when creating or editing an order")
        static let couponsErrorNoticeTitle = NSLocalizedString("Unable to add coupon.",
                                                                 comment: "Info message when the user tries to add a coupon" +
                                                                 "that is not applicated to the products")
        static let couponsErrorNoticeMessage = NSLocalizedString("Sorry, this coupon is not applicable to selected products.",
                                                                 comment: "Info message when the user tries to add a coupon" +
                                                                 "that is not applicated to the products")
        static let setNewTaxRate = NSLocalizedString("Set New Tax Rate", comment: "Button title to set a new tax rate to an order")
        static let editTaxRateSetting = NSLocalizedString("Edit Tax Rate Setting", comment: "Button title to edit the selected tax rate to apply to the order")
        static let newTaxRateSetSuccessMessage = NSLocalizedString("🎉 New tax rate set", comment: "Message when a tax rate is set")
        static let stopAddingTaxRateAutomaticallySuccessMessage = NSLocalizedString("Stopped automatically adding tax rate",
                                                                                    comment: "Message when the user disables adding tax rates automatically")
        static let customAmountDefaultName = NSLocalizedString("editableOrderViewModel.customAmountDefaultName",
                                                               value: "Custom Amount",
                                                               comment: "Default name when the custom amount does not have a name in order creation.")
        static let parentProductScannedNoticeTitle = NSLocalizedString(
            "order.barcode.scan.parent.product.notice.title",
            value: "You cannot add a variable product directly.",
            comment: "Title of a notice shown when a merchant scans a barcode for a product which is a parent to variations. " +
            "It's not possible to purchase a parent product, as it simply groups its variable product children. " +
            "In this case, the product is not added to the order as the merchant wanted it to be.")
        static let parentProductScannedNoticeSubtitle = NSLocalizedString(
            "order.barcode.scan.parent.product.notice.subtitle",
            value: "Please select a specific variation.",
            comment: "Subtitle of a notice shown when a merchant scans a barcode for a product which is a parent to variations. " +
            "It's not possible to purchase a parent product, as it simply groups its variable product children. " +
            "In this case, the product is not added to the order as the merchant wanted it to be.")


        enum CouponSummary {
            static let singular = NSLocalizedString("Coupon (%1$@)",
                                                   comment: "The singular coupon summary. Reads like: Coupon (code1)")
            static let plural = NSLocalizedString("Coupons (%1$@)",
                                                   comment: "The plural coupon summary. Reads like: Coupon (code1, code2)")
        }
    }

    enum SystemPluginPaths {
        static let giftCards = "woocommerce-gift-cards/woocommerce-gift-cards.php"
    }

    enum Constants {
        static let quantityDebounceDuration = 0.5
    }
}

extension TaxBasedOnSetting {
    var displayString: String {
        switch self {
        case .customerBillingAddress:
            return NSLocalizedString("editableOrderViewModel.taxBasedOnSetting.customerBillingAddress",
                                     value: "Calculated on billing address.",
                                     comment: "The string to show on order taxes when they are calculated based on the billing address")
        case .customerShippingAddress:
            return NSLocalizedString("editableOrderViewModel.taxBasedOnSetting.customerShippingAddress",
                                     value: "Calculated on shipping address.",
                                     comment: "The string to show on order taxes when they are calculated based on the shipping address")
        case .shopBaseAddress:
            return NSLocalizedString("editableOrderViewModel.taxBasedOnSetting.shopBaseAddress",
                                     value: "Calculated on shop base address.",
                                     comment: "The string to show on order taxes when they are calculated based on the shop base address")
        }
    }
}
