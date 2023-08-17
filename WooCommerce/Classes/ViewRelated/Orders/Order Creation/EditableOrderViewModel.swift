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

    /// Indicates whether the cancel button is visible.
    ///
    var shouldShowCancelButton: Bool {
        featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) && flow == .creation
    }

    /// Indicates the customer details screen to be shown. If there's no address added show the customer selector, otherwise the form so it can be edited
    ///
    var customerNavigationScreen: CustomerNavigationScreen {
        let shouldShowSelector = featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) &&
        // If there are no addresses added
        orderSynchronizer.order.billingAddress == nil &&
        orderSynchronizer.order.shippingAddress == nil

        return shouldShowSelector ? .selector : .form
    }

    var shouldShowSearchButtonInOrderAddressForm: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    /// Indicates whether adding a product to the order via SKU scanning is enabled
    ///
    var isAddProductToOrderViaSKUScannerEnabled: Bool {
        featureFlagService.isFeatureFlagEnabled(.addProductToOrderViaSKUScanner)
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
    @Published private(set) var navigationTrailingItem: NavigationItem = .create

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

    // MARK: Status properties

    /// Order creation date. For new order flow it's always current date.
    ///
    var dateString: String {
        switch flow {
        case .creation:
            return DateFormatter.mediumLengthLocalizedDateFormatter.string(from: Date())
        case .editing(let order):
            let formatter = DateFormatter.dateAndTimeFormatter
            return formatter.string(from: order.dateCreated)
        }
    }

    /// Representation of order status display properties.
    ///
    @Published private(set) var statusBadgeViewModel: StatusBadgeViewModel = .init(orderStatusEnum: .pending)

    /// Indicates if the order status list (selector) should be shown or not.
    ///
    @Published var shouldShowOrderStatusList: Bool = false

    /// Defines if the view should be disabled.
    @Published private(set) var disabled: Bool = false

    /// Defines if the non editable indicators (banners, locks, fields) should be shown.
    @Published private(set) var shouldShowNonEditableIndicators: Bool = false

    /// Defines the multiple lines info message to show.
    ///
    @Published private(set) var multipleLinesMessage: String? = nil

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
    @Published private(set) var productRows: [ProductRowViewModel] = []

    /// Selected product view model to render.
    /// Used to open the product details in `ProductInOrder`.
    ///
    @Published var selectedProductViewModel: ProductInOrderViewModel? = nil

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

    // MARK: Customer data properties

    /// Representation of customer data display properties.
    ///
    @Published private(set) var customerDataViewModel: CustomerDataViewModel = .init(billingAddress: nil, shippingAddress: nil)

    /// View model for the customer details address form.
    ///
    @Published private(set) var addressFormViewModel: CreateOrderAddressFormViewModel

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

    /// Saves a shipping line.
    ///
    /// - Parameter shippingLine: Optional shipping line object to save. `nil` will remove existing shipping line.
    func saveShippingLine(_ shippingLine: ShippingLine?) {
        orderSynchronizer.setShipping.send(shippingLine)

        if shippingLine != nil {
            analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodAdd(flow: flow.analyticsFlow))
        } else {
            analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodRemove(flow: flow.analyticsFlow))
        }
    }

    /// Saves a fee.
    ///
    /// - Parameter formattedFeeLine: Optional fee line object to save. `nil` will remove existing fee line.
    /// 
    func saveFeeLine(_ formattedFeeLine: String?) {
        guard let formattedFeeLine = formattedFeeLine else {
            return removeFee()
        }

        addFee(formattedFeeLine)
    }

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

    /// Analytics engine.
    ///
    private let analytics: Analytics

    /// Order Synchronizer helper.
    ///
    private let orderSynchronizer: OrderSynchronizer

    /// Initial product or variation given to the order when is created, if any
    ///
    private let initialItem: OrderBaseItem?

    private let orderDurationRecorder: OrderDurationRecorderProtocol

    private let barcodeSKUScannerItemFinder: BarcodeSKUScannerItemFinder

    init(siteID: Int64,
         flow: Flow = .creation,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         initialItem: OrderBaseItem? = nil) {
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
        self.barcodeSKUScannerItemFinder = BarcodeSKUScannerItemFinder(stores: stores)

        // Set a temporary initial view model, as a workaround to avoid making it optional.
        // Needs to be reset before the view model is used.
        self.addressFormViewModel = .init(siteID: siteID, addressData: .init(billingAddress: nil, shippingAddress: nil), onAddressUpdate: nil)

        configureDisabledState()
        configureNavigationTrailingItem()
        configureSyncErrors()
        configureStatusBadgeViewModel()
        configureProductRowViewModels()
        configureCustomerDataViewModel()
        configurePaymentDataViewModel()
        configureCustomerNoteDataViewModel()
        configureNonEditableIndicators()
        configureMultipleLinesMessage()
        resetAddressForm()
        syncInitialSelectedState()
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

    /// View model for the product list, initialized with the selected order items
    ///
    func createProductSelectorViewModelWithOrderItemsSelected() -> ProductSelectorViewModel {
        ProductSelectorViewModel(
            siteID: siteID,
            selectedItemIDs: selectedProductsAndVariationsIDs,
            purchasableItemsOnly: true,
            storageManager: storageManager,
            stores: stores,
            toggleAllVariationsOnSelection: false,
            topProductsProvider: TopProductsFromCachedOrdersProvider(),
            onProductSelectionStateChanged: { [weak self] product in
                guard let self = self else { return }
                self.changeSelectionStateForProduct(product)
            },
            onVariationSelectionStateChanged: { [weak self] variation, parentProduct in
                guard let self = self else { return }
                self.changeSelectionStateForProductVariation(variation, parent: parentProduct)
            }, onMultipleSelectionCompleted: { [weak self] _ in
                guard let self = self else { return }
                self.syncOrderItems(products: self.selectedProducts, variations: self.selectedProductVariations)
            }, onAllSelectionsCleared: { [weak self] in
                guard let self = self else { return }
                self.clearAllSelectedItems()
                self.trackClearAllSelectedItemsTapped()
            }, onSelectedVariationsCleared: { [weak self] in
                guard let self = self else { return }
                self.clearSelectedVariations()
            }, onCloseButtonTapped: { [weak self] in
                guard let self = self else { return }
                self.syncOrderItemSelectionStateOnDismiss()
            })
    }

    /// Synchronizes the item selection state by clearing all items, then retrieving the latest saved state
    ///
    func syncOrderItemSelectionStateOnDismiss() {
        clearAllSelectedItems()
        syncInitialSelectedState()
    }

    /// Selects an order item by setting the `selectedProductViewModel`.
    ///
    /// - Parameter id: ID of the order item to select
    func selectOrderItem(_ id: Int64) {
        selectedProductViewModel = createSelectedProductViewModel(itemID: id)
    }

    /// Removes an item from the order.
    ///
    /// - Parameter item: Item to remove from the order
    func removeItemFromOrder(_ item: OrderItem) {
        guard let input = createUpdateProductInput(item: item, quantity: 0) else { return }
        orderSynchronizer.setProduct.send(input)

        if item.variationID != 0 {
            selectedProductVariations.removeAll(where: { $0.productVariationID == item.variationID })
        } else if item.productID != 0 {
            selectedProducts.removeAll(where: { $0.productID == item.productID })
        }

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
    }

    func addDiscountToOrderItem(item: OrderItem, discount: Decimal) {
        guard let productInput = createUpdateProductInput(item: item, quantity: item.quantity, discount: discount) else {
            return
        }

        orderSynchronizer.setProduct.send(productInput)
    }

    /// Creates a view model for the `ProductRow` corresponding to an order item.
    ///
    func createProductRowViewModel(for item: OrderItem, canChangeQuantity: Bool) -> ProductRowViewModel? {
        guard item.quantity > 0 else {
            // Don't render any item with `.zero` quantity.
            return nil
        }

        let itemDiscount = currentDiscount(on: item)
        let passingDiscountValue = itemDiscount > 0 ? itemDiscount : nil

        if item.variationID != 0,
            let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
            let parent = allProducts.first(where: { $0.productID == item.parent })
            let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: parent?.attributes ?? [])
            return ProductRowViewModel(id: item.itemID,
                                       productVariation: variation,
                                       discount: passingDiscountValue,
                                       name: item.name,
                                       quantity: item.quantity,
                                       canChangeQuantity: canChangeQuantity,
                                       displayMode: .attributes(attributes),
                                       quantityUpdatedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductQuantityChange(flow: self.flow.analyticsFlow))
            },
                                       removeProductIntent: { [weak self] in
                self?.removeItemFromOrder(item)})
        } else if let product = allProducts.first(where: { $0.productID == item.productID }) {
            return ProductRowViewModel(id: item.itemID,
                                       product: product,
                                       discount: passingDiscountValue,
                                       quantity: item.quantity,
                                       canChangeQuantity: canChangeQuantity,
                                       quantityUpdatedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductQuantityChange(flow: self.flow.analyticsFlow))
            },
                                       removeProductIntent: { [weak self] in
                self?.removeItemFromOrder(item)})
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
        addressFormViewModel = CreateOrderAddressFormViewModel(siteID: siteID,
                                                               addressData: .init(billingAddress: orderSynchronizer.order.billingAddress,
                                                                                  shippingAddress: orderSynchronizer.order.shippingAddress),
                                                               onAddressUpdate: { [weak self] updatedAddressData in
            let input = Self.createAddressesInputIfPossible(billingAddress: updatedAddressData.billingAddress,
                                                            shippingAddress: updatedAddressData.shippingAddress)
            self?.orderSynchronizer.setAddresses.send(input)
            self?.trackCustomerDetailsAdded()
        })
    }

    func addCustomerAddressToOrder(customer: Customer) {
        let input = Self.createAddressesInputIfPossible(billingAddress: customer.billing, shippingAddress: customer.shipping)
        orderSynchronizer.setAddresses.send(input)
        resetAddressForm()
    }

    /// Updates the order creation draft with the current set customer note.
    ///
    func updateCustomerNote() {
        orderSynchronizer.setNote.send(noteViewModel.newNote)
        trackCustomerNoteAdded()
    }

    // MARK: - API Requests
    /// Creates an order remotely using the provided order details.
    ///
    func createOrder() {
        performingNetworkRequest = true

        orderSynchronizer.commitAllChanges { [weak self] result in
            guard let self = self else { return }
            self.performingNetworkRequest = false

            switch result {
            case .success(let newOrder):
                self.onFinished(newOrder)
                self.trackCreateOrderSuccess()
            case .failure(let error):
                self.fixedNotice = NoticeFactory.createOrderErrorNotice(error, order: self.orderSynchronizer.order)
                self.trackCreateOrderFailure(error: error)
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        trackCreateButtonTapped()
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
}

// MARK: - Types
extension EditableOrderViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case create
        case done
        case loading
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
        let siteID: Int64
        let itemsTotal: String
        let orderTotal: String

        let shouldShowShippingTotal: Bool
        let shippingTotal: String

        // We only support one (the first) shipping line
        let shippingMethodTitle: String
        let shippingMethodTotal: String

        let shouldShowFees: Bool
        let feesBaseAmountForPercentage: Decimal
        let feesTotal: String

        // We only support one (the first) fee line
        let feeLineTotal: String

        let taxesTotal: String

        let couponLineViewModels: [CouponLineViewModel]
        let couponCode: String
        var discountTotal: String
        let shouldShowDiscountTotal: Bool
        let shouldShowCoupon: Bool
        let shouldDisableAddingCoupons: Bool

        /// Whether payment data is being reloaded (during remote sync)
        ///
        let isLoading: Bool

        let showNonEditableIndicators: Bool

        let shippingLineViewModel: ShippingLineDetailsViewModel
        let feeLineViewModel: FeeOrDiscountLineDetailsViewModel
        let addNewCouponLineClosure: (Coupon) -> Void
        let onGoToCouponsClosure: () -> Void

        init(siteID: Int64 = 0,
             itemsTotal: String = "0",
             shouldShowShippingTotal: Bool = false,
             shippingTotal: String = "0",
             shippingMethodTitle: String = "",
             shippingMethodTotal: String = "",
             shouldShowFees: Bool = false,
             feesBaseAmountForPercentage: Decimal = 0,
             feesTotal: String = "0",
             feeLineTotal: String = "0",
             taxesTotal: String = "0",
             orderTotal: String = "0",
             shouldShowCoupon: Bool = false,
             shouldDisableAddingCoupons: Bool = false,
             couponLineViewModels: [CouponLineViewModel] = [],
             couponCode: String = "",
             discountTotal: String = "",
             shouldShowDiscountTotal: Bool = false,
             isLoading: Bool = false,
             showNonEditableIndicators: Bool = false,
             saveShippingLineClosure: @escaping (ShippingLine?) -> Void = { _ in },
             saveFeeLineClosure: @escaping (String?) -> Void = { _ in },
             addNewCouponLineClosure: @escaping (Coupon) -> Void = { _ in },
             onGoToCouponsClosure: @escaping () -> Void = {},
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
            self.siteID = siteID
            self.itemsTotal = currencyFormatter.formatAmount(itemsTotal) ?? "0.00"
            self.shouldShowShippingTotal = shouldShowShippingTotal
            self.shippingTotal = currencyFormatter.formatAmount(shippingTotal) ?? "0.00"
            self.shippingMethodTitle = shippingMethodTitle
            self.shippingMethodTotal = currencyFormatter.formatAmount(shippingMethodTotal) ?? "0.00"
            self.shouldShowFees = shouldShowFees
            self.feesBaseAmountForPercentage = feesBaseAmountForPercentage
            self.feesTotal = currencyFormatter.formatAmount(feesTotal) ?? "0.00"
            self.feeLineTotal = currencyFormatter.formatAmount(feeLineTotal) ?? "0.00"
            self.taxesTotal = currencyFormatter.formatAmount(taxesTotal) ?? "0.00"
            self.orderTotal = currencyFormatter.formatAmount(orderTotal) ?? "0.00"
            self.isLoading = isLoading
            self.showNonEditableIndicators = showNonEditableIndicators
            self.shouldShowCoupon = shouldShowCoupon
            self.shouldDisableAddingCoupons = shouldDisableAddingCoupons
            self.couponLineViewModels = couponLineViewModels
            self.couponCode = couponCode
            self.discountTotal = "-" + (currencyFormatter.formatAmount(discountTotal) ?? "0.00")
            self.shouldShowDiscountTotal = shouldShowDiscountTotal
            self.shippingLineViewModel = ShippingLineDetailsViewModel(isExistingShippingLine: shouldShowShippingTotal,
                                                                      initialMethodTitle: shippingMethodTitle,
                                                                      shippingTotal: shippingMethodTotal,
                                                                      didSelectSave: saveShippingLineClosure)
            self.feeLineViewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: shouldShowFees,
                                                                      baseAmountForPercentage: feesBaseAmountForPercentage,
                                                                      initialTotal: feeLineTotal,
                                                                      lineType: .fee,
                                                            didSelectSave: saveFeeLineClosure)
            self.addNewCouponLineClosure = addNewCouponLineClosure
            self.onGoToCouponsClosure = onGoToCouponsClosure
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

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func configureNavigationTrailingItem() {
        Publishers.CombineLatest4(orderSynchronizer.orderPublisher, orderSynchronizer.statePublisher, $performingNetworkRequest, Just(flow))
            .map { order, syncState, performingNetworkRequest, flow -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                switch (flow, syncState) {
                case (.creation, _):
                    return .create
                case (.editing, .syncing):
                    return .loading
                case (.editing, _):
                    return .done
                }
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Updates the notice based on the `orderSynchronizer` sync state.
    ///
    func configureSyncErrors() {
        orderSynchronizer.statePublisher
            .map { [weak self] state in
                guard let self = self else { return nil }
                switch state {
                case .error(let error):
                    DDLogError("⛔️ Error syncing order remotely: \(error)")
                    self.trackSyncOrderFailure(error: error)
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
            if !itemsInOrder.contains(where: { $0.productID == product.productID }) {
                productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1))
            }
        }

        for variation in variations {
            // Only perform the operation if the variation has not been already added to the existing Order
            if !itemsInOrder.contains(where: { $0.productOrVariationID == variation.productVariationID }) {
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
            return item.variationID == 0 && !products.contains(where: { $0?.productID == item.productID })
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
        orderSynchronizer.setProducts.send(addedItemsToSync + removedItemsToSync)

        let productCount = addedItemsToSync.count - removedItemsToSync.count

        if addedItemsToSync.isNotEmpty {
            analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: flow.analyticsFlow,
                                                                            source: .orderCreation,
                                                                            addedVia: .manually,
                                                                            productCount: productCount))
        }

        if removedItemsToSync.isNotEmpty {
            analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
        }
    }

    /// Adds a selected product (from the product list) to the order.
    ///
    func changeSelectionStateForProduct(_ product: Product) {
        // Needed because `allProducts` is only updated at start, so product from new pages are not synced.
        allProducts.insert(product)

        if !selectedProducts.contains(where: { $0.productID == product.productID }) {
            selectedProducts.append(product)
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemSelected(productType: .product))
        } else {
            selectedProducts.removeAll(where: { $0.productID == product.productID })
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemUnselected(productType: .product))
        }
    }

    /// Adds a selected product variation (from the product list) to the order.
    ///
    func changeSelectionStateForProductVariation(_ variation: ProductVariation, parent product: Product) {
        // Needed because `allProducts` is only updated at start, so product from new pages are not synced.
        allProducts.insert(product)
        allProductVariations.insert(variation)

        if !selectedProductVariations.contains(where: { $0.productVariationID == variation.productVariationID }) {
            selectedProductVariations.append(variation)
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorItemSelected(productType: .variation))
        } else {
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
            .map { [weak self] items -> [ProductRowViewModel] in
                guard let self = self else { return [] }
                return self.createProductRows(items: items)
            }
            .assign(to: &$productRows)
        configureOrderWithinitialItemIfNeeded()
    }

    /// If given an initial product ID on initialization, updates the Order with the item
    ///
    func configureOrderWithinitialItemIfNeeded() {
        guard let item = initialItem else {
            return
        }

        updateOrderWithBaseItem(item)
    }

    /// Updates the Order with the given product
    ///
    func updateOrderWithBaseItem(_ item: OrderBaseItem) {
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
        let match = productRows.first(where: { $0.productOrVariationID == item.itemID })
        match?.incrementQuantity()
    }

    /// Updates customer data viewmodel based on order addresses.
    ///
    func configureCustomerDataViewModel() {
        orderSynchronizer.orderPublisher
            .map {
                CustomerDataViewModel(billingAddress: $0.billingAddress, shippingAddress: $0.shippingAddress)
            }
            .assign(to: &$customerDataViewModel)
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
        Publishers.CombineLatest3(orderSynchronizer.orderPublisher, orderSynchronizer.statePublisher, $shouldShowNonEditableIndicators)
            .map { [weak self] order, state, showNonEditableIndicators in
                guard let self = self else {
                    return PaymentDataViewModel()
                }

                let orderTotals = OrderTotalsCalculator(for: order, using: self.currencyFormatter)

                let shippingMethodTitle = order.shippingLines.first?.methodTitle ?? ""

                let isDataSyncing: Bool = {
                    switch state {
                    case .syncing:
                        return true
                    default:
                        return false
                    }
                }()

                return PaymentDataViewModel(siteID: self.siteID,
                                            itemsTotal: orderTotals.itemsTotal.stringValue,
                                            shouldShowShippingTotal: order.shippingLines.filter { $0.methodID != nil }.isNotEmpty,
                                            shippingTotal: order.shippingTotal.isNotEmpty ? order.shippingTotal : "0",
                                            shippingMethodTitle: shippingMethodTitle,
                                            shippingMethodTotal: order.shippingLines.first?.total ?? "0",
                                            shouldShowFees: order.fees.filter { $0.name != nil }.isNotEmpty,
                                            feesBaseAmountForPercentage: orderTotals.feesBaseAmountForPercentage as Decimal,
                                            feesTotal: orderTotals.feesTotal.stringValue,
                                            feeLineTotal: order.fees.first?.total ?? "0",
                                            taxesTotal: order.totalTax.isNotEmpty ? order.totalTax : "0",
                                            orderTotal: order.total.isNotEmpty ? order.total : "0",
                                            shouldShowCoupon: order.coupons.isNotEmpty,
                                            shouldDisableAddingCoupons: order.items.isEmpty,
                                            couponLineViewModels: self.couponLineViewModels(from: order.coupons),
                                            couponCode: order.coupons.first?.code ?? "",
                                            discountTotal: orderTotals.discountTotal.stringValue,
                                            shouldShowDiscountTotal: order.discountTotal.isNotEmpty,
                                            isLoading: isDataSyncing && !showNonEditableIndicators,
                                            showNonEditableIndicators: showNonEditableIndicators,
                                            saveShippingLineClosure: self.saveShippingLine,
                                            saveFeeLineClosure: self.saveFeeLine,
                                            addNewCouponLineClosure: { [weak self] coupon in
                                                self?.saveCouponLine(result: .added(newCode: coupon.code))
                                            },
                                            onGoToCouponsClosure: { [weak self] in
                                                self?.analytics.track(event: WooAnalyticsEvent.Orders.orderGoToCouponsButtonTapped())
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

    /// Binds the order state to the `multipleLineMessage` property.
    ///
    func configureMultipleLinesMessage() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, Just(flow))
            .map { order, flow -> String? in
                switch (flow, order.shippingLines.count, order.fees.count) {
                case (.creation, _, _):
                    return nil
                case (.editing, 2...Int.max, 0...1): // Multiple shipping lines
                    return Localization.multipleShippingLines
                case (.editing, 0...1, 2...Int.max): // Multiple fee lines
                    return Localization.multipleFeeLines
                case (.editing, 2...Int.max, 2...Int.max): // Multiple shipping & fee lines
                    return Localization.multipleFeesAndShippingLines
                case (.editing, _, _): // Single/nil shipping & fee lines
                    return nil
                }
            }
            .assign(to: &$multipleLinesMessage)
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
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreateButtonTapped(status: orderSynchronizer.order.status,
                                                                                productCount: orderSynchronizer.order.items.count,
                                                                                hasCustomerDetails: hasCustomerDetails,
                                                                                hasFees: orderSynchronizer.order.fees.isNotEmpty,
                                                                                hasShippingMethod: orderSynchronizer.order.shippingLines.isNotEmpty))
    }

    /// Tracks an order creation success
    ///
    func trackCreateOrderSuccess() {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationSuccess(millisecondsSinceSinceOrderAddNew:
                                                                                try? orderDurationRecorder.millisecondsSinceOrderAddNew(),
                                                                             couponsCount: Int64(orderSynchronizer.order.coupons.count)))
    }

    /// Tracks an order creation failure
    ///
    func trackCreateOrderFailure(error: Error) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationFailed(errorContext: String(describing: error),
                                                                            errorDescription: error.localizedDescription))
    }

    /// Tracks an order remote sync failure
    ///
    func trackSyncOrderFailure(error: Error) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderSyncFailed(flow: flow.analyticsFlow,
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
    private func createUpdateProductInput(item: OrderItem, quantity: Decimal, discount: Decimal? = nil) -> OrderSyncProductInput? {
        // Finds the product or productVariation associated with the order item.
        let product: OrderSyncProductInput.ProductType? = {
            if item.variationID != 0, let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
                return .variation(variation)
            }

            if let product = allProducts.first(where: { $0.productID == item.productID }) {
                return .product(product)
            }

            return nil
        }()

        guard let product = product else {
            DDLogError("⛔️ Product with ID: \(item.productID) not found.")
            return nil
        }

        // Return a new input with the new quantity but with the same item id to properly reference the update.
        return OrderSyncProductInput(id: item.itemID, product: product, quantity: quantity, discount: discount ?? currentDiscount(on: item))
    }

    /// Creates a `ProductInOrderViewModel` based on the provided order item id.
    ///
    func createSelectedProductViewModel(itemID: Int64) -> ProductInOrderViewModel? {
        // Find order item based on the provided id.
        // Creates the product row view model needed for `ProductInOrderViewModel`.
        guard let orderItem = orderSynchronizer.order.items.first(where: { $0.itemID == itemID }),
              let rowViewModel = createProductRowViewModel(for: orderItem, canChangeQuantity: false) else {
            return nil
        }

        return ProductInOrderViewModel(productRowViewModel: rowViewModel,
                                       productDiscountConfiguration: addProductDiscountConfiguration(on: orderItem),
                                       showCouponsAndDiscountsAlert: orderSynchronizer.order.coupons.isNotEmpty &&
                                                                     featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4),
                                       onRemoveProduct: { [weak self] in
                                            self?.removeItemFromOrder(orderItem)
                                       })
    }

    /// Creates the configuration related to adding a discount to a product. If the feature shouldn't be shown it returns `nil`
    ///
    func addProductDiscountConfiguration(on orderItem: OrderItem) -> ProductInOrderViewModel.DiscountConfiguration? {
        guard featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4),
              orderSynchronizer.order.coupons.isEmpty,
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
    func createProductRows(items: [OrderItem]) -> [ProductRowViewModel] {
        items.compactMap { item -> ProductRowViewModel? in
            guard let productRowViewModel = self.createProductRowViewModel(for: item, canChangeQuantity: true) else {
                return nil
            }

            // Observe changes to the product quantity
            productRowViewModel.$quantity
                .dropFirst() // Omit the default/initial quantity to prevent a double trigger.
                .sink { [weak self] newQuantity in
                    guard let self = self, let newInput = self.createUpdateProductInput(item: item, quantity: newQuantity) else {
                        return
                    }
                    self.orderSynchronizer.setProduct.send(newInput)
                }
                .store(in: &self.cancellables)

            return productRowViewModel
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
                if let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
                    selectedProductVariations.append(variation)
                }
            } else {
                if let product = allProducts.first(where: { $0.productID == item.productID }) {
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

    func addCoupon(with code: String) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCouponAdd(flow: flow.analyticsFlow))
        orderSynchronizer.addCoupon.send(code)
    }

    func removeCoupon(with code: String) {
        analytics.track(event: WooAnalyticsEvent.Orders.orderCouponRemove(flow: flow.analyticsFlow))
        orderSynchronizer.removeCoupon.send(code)
    }

    func addFee(_ formattedFeeLine: String) {
        let feeLine = OrderFactory.newOrderFee(total: formattedFeeLine)
        orderSynchronizer.setFee.send(feeLine)
        analytics.track(event: WooAnalyticsEvent.Orders.orderFeeAdd(flow: flow.analyticsFlow))
    }

    func removeFee() {
        orderSynchronizer.setFee.send(nil)
        analytics.track(event: WooAnalyticsEvent.Orders.orderFeeRemove(flow: flow.analyticsFlow))
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
        analytics.track(event: WooAnalyticsEvent.Orders.barcodeScanningSuccess(from: .orderCreation))
        mapScannedBarcodetoBaseItem(barcode: barcode) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(result):
                Task { @MainActor in
                    self.analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: self.flow.analyticsFlow,
                                                                                    source: .orderCreation,
                                                                                    addedVia: .scanning))
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
        analytics.track(event: WooAnalyticsEvent.Orders.barcodeScanningFailure(from: .orderCreation, reason: .cameraAccessNotPermitted))
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

        static let multipleShippingLines = NSLocalizedString("Shipping details are incomplete.\n" +
                                                             "To edit all shipping details, view the order in your WooCommerce store admin.",
                                                             comment: "Info message shown when the order contains multiple shipping lines")
        static let multipleFeeLines = NSLocalizedString("Fees are incomplete.\n" +
                                                        "To edit all fees, view the order in your WooCommerce store admin.",
                                                        comment: "Info message shown when the order contains multiple fee lines")
        static let multipleFeesAndShippingLines = NSLocalizedString("Fees & Shipping details are incomplete.\n" +
                                                                    "To edit all the details, view the order in your WooCommerce store admin.",
                                                                    comment: "Info message shown when the order contains multiple fees and shipping lines")
        static let couponsErrorNoticeTitle = NSLocalizedString("Unable to add coupon.",
                                                                 comment: "Info message when the user tries to add a coupon" +
                                                                 "that is not applicated to the products")
        static let couponsErrorNoticeMessage = NSLocalizedString("Sorry, this coupon is not applicable to selected products.",
                                                                 comment: "Info message when the user tries to add a coupon" +
                                                                 "that is not applicated to the products")

        enum CouponSummary {
            static let singular = NSLocalizedString("Coupon (%1$@)",
                                                   comment: "The singular coupon summary. Reads like: Coupon (code1)")
            static let plural = NSLocalizedString("Coupons (%1$@)",
                                                   comment: "The plural coupon summary. Reads like: Coupon (code1, code2)")
        }
    }
}
