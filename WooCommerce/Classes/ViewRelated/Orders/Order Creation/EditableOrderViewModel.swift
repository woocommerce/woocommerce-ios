import Yosemite
import Combine
import protocol Storage.StorageManagerType
import Experiments
import WooFoundation
import enum Networking.DotcomError

/// View model used in Order Creation and Editing flows.
///
final class EditableOrderViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let featureFlagService: FeatureFlagService

    private var cancellables: Set<AnyCancellable> = []

    enum Flow: Equatable {
        case creation
        case editing(initialOrder: Order)
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

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

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
    private var allProducts: [Product] = []

    /// Product Variations Results Controller.
    ///
    private lazy var productVariationsResultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    /// Product Variations list
    ///
    private var allProductVariations: [ProductVariation] = []

    /// View model for the product list
    ///
    lazy var addProductViewModel = {
        ProductSelectorViewModel(siteID: siteID, purchasableItemsOnly: true, storageManager: storageManager, stores: stores) { [weak self] product in
            guard let self = self else { return }
            self.addProductToOrder(product)
        } onVariationSelected: { [weak self] variation in
            guard let self = self else { return }
            self.addProductVariationToOrder(variation)
        }
    }()

    /// View models for each product row in the order.
    ///
    @Published private(set) var productRows: [ProductRowViewModel] = []

    /// Selected product view model to render.
    /// Used to open the product details in `ProductInOrder`.
    ///
    @Published var selectedProductViewModel: ProductInOrderViewModel? = nil

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
            analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodAdd(flow: .creation))
        }
    }

    /// Saves a fee.
    ///
    /// - Parameter shippingLine: Optional shipping line object to save. `nil` will remove existing shipping line.
    func saveFeeLine(_ feeLine: OrderFeeLine?) {
        orderSynchronizer.setFee.send(feeLine)

        if feeLine != nil {
            analytics.track(event: WooAnalyticsEvent.Orders.orderFeeAdd(flow: .creation))
        }
    }

    // MARK: -

    /// Defines the current order status.
    ///
    var currentOrderStatus: OrderStatusEnum {
        orderSynchronizer.order.status
    }

    /// Analytics engine.
    ///
    private let analytics: Analytics

    /// Order Synchronizer helper.
    ///
    private let orderSynchronizer: OrderSynchronizer

    init(siteID: Int64,
         flow: Flow = .creation,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.flow = flow
        self.stores = stores
        self.storageManager = storageManager
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
        self.orderSynchronizer = RemoteOrderSynchronizer(siteID: siteID, flow: flow, stores: stores, currencySettings: currencySettings)
        self.featureFlagService = featureFlagService

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
        resetAddressForm()
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
    }

    /// Creates a view model for the `ProductRow` corresponding to an order item.
    ///
    func createProductRowViewModel(for item: OrderItem, canChangeQuantity: Bool) -> ProductRowViewModel? {
        guard item.quantity > 0, // Don't render any item with `.zero` quantity.
              let product = allProducts.first(where: { $0.productID == item.productID }) else {
            return nil
        }

        if item.variationID != 0, let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
            let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: product.attributes)
            return ProductRowViewModel(id: item.itemID,
                                       productVariation: variation,
                                       name: product.name,
                                       quantity: item.quantity,
                                       canChangeQuantity: canChangeQuantity,
                                       displayMode: .attributes(attributes),
                                       removeProductIntent: { [weak self] in
                self?.selectOrderItem(item.itemID) })
        } else {
            return ProductRowViewModel(id: item.itemID,
                                       product: product,
                                       quantity: item.quantity,
                                       canChangeQuantity: canChangeQuantity,
                                       removeProductIntent: { [weak self] in
                self?.selectOrderItem(item.itemID) })
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
            let input = Self.createAddressesInput(from: updatedAddressData)
            self?.orderSynchronizer.setAddresses.send(input)
            self?.trackCustomerDetailsAdded()
        })
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
                self.notice = NoticeFactory.createOrderErrorNotice(error, order: self.orderSynchronizer.order)
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
        analytics.track(event: WooAnalyticsEvent.Orders.orderStatusChange(flow: .creation, orderID: nil, from: oldStatus, to: newStatus))
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
        let itemsTotal: String
        let orderTotal: String

        let shouldShowShippingTotal: Bool
        let shippingTotal: String
        let shippingMethodTitle: String

        let shouldShowFees: Bool
        let feesBaseAmountForPercentage: Decimal
        let feesTotal: String

        let taxesTotal: String

        /// Whether payment data is being reloaded (during remote sync)
        ///
        let isLoading: Bool

        let showNonEditableIndicators: Bool

        let shippingLineViewModel: ShippingLineDetailsViewModel
        let feeLineViewModel: FeeLineDetailsViewModel

        init(itemsTotal: String = "0",
             shouldShowShippingTotal: Bool = false,
             shippingTotal: String = "0",
             shippingMethodTitle: String = "",
             shouldShowFees: Bool = false,
             feesBaseAmountForPercentage: Decimal = 0,
             feesTotal: String = "0",
             taxesTotal: String = "0",
             orderTotal: String = "0",
             isLoading: Bool = false,
             showNonEditableIndicators: Bool = false,
             saveShippingLineClosure: @escaping (ShippingLine?) -> Void = { _ in },
             saveFeeLineClosure: @escaping (OrderFeeLine?) -> Void = { _ in },
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
            self.itemsTotal = currencyFormatter.formatAmount(itemsTotal) ?? "0.00"
            self.shouldShowShippingTotal = shouldShowShippingTotal
            self.shippingTotal = currencyFormatter.formatAmount(shippingTotal) ?? "0.00"
            self.shippingMethodTitle = shippingMethodTitle
            self.shouldShowFees = shouldShowFees
            self.feesBaseAmountForPercentage = feesBaseAmountForPercentage
            self.feesTotal = currencyFormatter.formatAmount(feesTotal) ?? "0.00"
            self.taxesTotal = currencyFormatter.formatAmount(taxesTotal) ?? "0.00"
            self.orderTotal = currencyFormatter.formatAmount(orderTotal) ?? "0.00"
            self.isLoading = isLoading
            self.showNonEditableIndicators = showNonEditableIndicators
            self.shippingLineViewModel = ShippingLineDetailsViewModel(isExistingShippingLine: shouldShowShippingTotal,
                                                                      initialMethodTitle: shippingMethodTitle,
                                                                      shippingTotal: self.shippingTotal,
                                                                      didSelectSave: saveShippingLineClosure)
            self.feeLineViewModel = FeeLineDetailsViewModel(isExistingFeeLine: shouldShowFees,
                                                            baseAmountForPercentage: feesBaseAmountForPercentage,
                                                            feesTotal: self.feesTotal,
                                                            didSelectSave: saveFeeLineClosure)
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
            .assign(to: &$notice)
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

    /// Adds a selected product (from the product list) to the order.
    ///
    func addProductToOrder(_ product: Product) {
        if !allProducts.contains(product) {
            allProducts.append(product)
        }

        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        orderSynchronizer.setProduct.send(input)

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: .creation))
    }

    /// Adds a selected product variation (from the product list) to the order.
    ///
    func addProductVariationToOrder(_ variation: ProductVariation) {
        if !allProductVariations.contains(variation) {
            allProductVariations.append(variation)
        }

        let input = OrderSyncProductInput(product: .variation(variation), quantity: 1)
        orderSynchronizer.setProduct.send(input)

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: .creation))
    }

    /// Configures product row view models for each item in `orderDetails`.
    ///
    func configureProductRowViewModels() {
        updateProductsResultsController()
        updateProductVariationsResultsController()
        orderSynchronizer.orderPublisher
            .map { $0.items }
            .removeDuplicates()
            .map { [weak self] items -> [ProductRowViewModel] in
                guard let self = self else { return [] }
                return self.createProductRows(items: items)
            }
            .assign(to: &$productRows)
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

                return PaymentDataViewModel(itemsTotal: orderTotals.itemsTotal.stringValue,
                                            shouldShowShippingTotal: order.shippingLines.filter { $0.methodID != nil }.isNotEmpty,
                                            shippingTotal: order.shippingTotal.isNotEmpty ? order.shippingTotal : "0",
                                            shippingMethodTitle: shippingMethodTitle,
                                            shouldShowFees: order.fees.filter { $0.name != nil }.isNotEmpty,
                                            feesBaseAmountForPercentage: orderTotals.feesBaseAmountForPercentage as Decimal,
                                            feesTotal: orderTotals.feesTotal.stringValue,
                                            taxesTotal: order.totalTax.isNotEmpty ? order.totalTax : "0",
                                            orderTotal: order.total.isNotEmpty ? order.total : "0",
                                            isLoading: isDataSyncing && !showNonEditableIndicators,
                                            showNonEditableIndicators: showNonEditableIndicators,
                                            saveShippingLineClosure: self.saveShippingLine,
                                            saveFeeLineClosure: self.saveFeeLine,
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
        analytics.track(event: WooAnalyticsEvent.Orders.orderCustomerAdd(flow: .creation, hasDifferentShippingDetails: areAddressesDifferent))
    }

    /// Tracks when customer note have been added
    ///
    func trackCustomerNoteAdded() {
        guard customerNoteDataViewModel.customerNote.isNotEmpty else { return }
        analytics.track(event: WooAnalyticsEvent.Orders.orderCustomerNoteAdd(flow: .creation))
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
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationSuccess())
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
        analytics.track(event: WooAnalyticsEvent.Orders.orderSyncFailed(errorContext: String(describing: error),
                                                                            errorDescription: error.localizedDescription))
    }

    /// Creates an `OrderSyncAddressesInput` type from a `NewOrderAddressData` type.
    /// Expects `billing` and `shipping` addresses to exists together,
    ///
    static func createAddressesInput(from data: CreateOrderAddressFormViewModel.NewOrderAddressData) -> OrderSyncAddressesInput? {
        guard let billingAddress = data.billingAddress, let shippingAddress = data.shippingAddress else {
            return nil
        }
        return OrderSyncAddressesInput(billing: billingAddress, shipping: shippingAddress)
    }

    /// Creates a new `OrderSyncProductInput` type meant to update an existing input from `OrderSynchronizer`
    /// If the referenced product can't be found, `nil` is returned.
    ///
    private func createUpdateProductInput(item: OrderItem, quantity: Decimal) -> OrderSyncProductInput? {
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
        return OrderSyncProductInput(id: item.itemID, product: product, quantity: quantity)
    }

    /// Creates a `ProductInOrderViewModel` based on the provided order item id.
    ///
    func createSelectedProductViewModel(itemID: Int64) -> ProductInOrderViewModel? {
        // Find order item based on the provided id.
        // Creates the product row view model needed for `ProductInOrderViewModel`.
        guard
            let orderItem = orderSynchronizer.order.items.first(where: { $0.itemID == itemID }),
            let rowViewModel = createProductRowViewModel(for: orderItem, canChangeQuantity: false)
        else {
            return nil
        }

        return ProductInOrderViewModel(productRowViewModel: rowViewModel) { [weak self] in
            self?.removeItemFromOrder(orderItem)
        }
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
            allProducts = productsResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Error fetching products for order: \(error)")
        }
    }

    /// Fetches product variations from storage.
    ///
    func updateProductVariationsResultsController() {
        do {
            try productVariationsResultsController.performFetch()
            allProductVariations = productVariationsResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Error fetching product variations for order: \(error)")
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

        /// Returns an order sync error notice.
        ///
        static func syncOrderErrorNotice(_ error: Error, flow: Flow, with orderSynchronizer: OrderSynchronizer) -> Notice {
            guard !isEmailError(error, order: orderSynchronizer.order) else {
                return Notice(title: Localization.invalidBillingParameters, message: Localization.invalidBillingSuggestion, feedbackType: .error)
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

        static let invalidBillingParameters =
        NSLocalizedString("Unable to set customer details.",
                          comment: "Error notice title when we fail to update an address when creating or editing an order.")
        static let invalidBillingSuggestion =
        NSLocalizedString("Please make sure you are running the latest version of WooCommerce and try again later.",
                          comment: "Recovery suggestion when we fail to update an address when creating or editing an order")
    }
}
