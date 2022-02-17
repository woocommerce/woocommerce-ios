import Yosemite
import Combine
import protocol Storage.StorageManagerType

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter

    private var cancellables: Set<AnyCancellable> = []

    /// Active navigation bar trailing item.
    /// Defaults to no visible button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .none

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
    let dateString: String = {
        DateFormatter.mediumLengthLocalizedDateFormatter.string(from: Date())
    }()

    /// Representation of order status display properties.
    ///
    @Published private(set) var statusBadgeViewModel: StatusBadgeViewModel = .init(orderStatusEnum: .pending)

    /// Indicates if the order status list (selector) should be shown or not.
    ///
    @Published var shouldShowOrderStatusList: Bool = false

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
    private var allProducts: [Product] {
        productsResultsController.fetchedObjects
    }

    /// Product Variations Results Controller.
    ///
    private lazy var productVariationsResultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    /// Product Variations list
    ///
    private var allProductVariations: [ProductVariation] {
        productVariationsResultsController.fetchedObjects
    }

    /// View model for the product list
    ///
    lazy var addProductViewModel = {
        AddProductToOrderViewModel(siteID: siteID, storageManager: storageManager, stores: stores) { [weak self] product in
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

    // MARK: Payment properties

    /// Indicates if the Payment section should be shown
    ///
    var shouldShowPaymentSection: Bool {
        orderSynchronizer.order.items.isNotEmpty
    }

    /// Representation of payment data display properties
    ///
    @Published private(set) var paymentDataViewModel = PaymentDataViewModel()

    /// Saves a shipping line.
    ///
    /// - Parameter shippingLine: Optional shipping line object to save. `nil` will remove existing shipping line.
    func saveShippingLine(_ shippingLine: ShippingLine?) {
        orderSynchronizer.setShipping.send(shippingLine)
    }

    // MARK: -

    /// Defines if the view should be disabled.
    /// Currently `true` while performing a network request.
    ///
    var disabled: Bool {
        performingNetworkRequest
    }

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
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
        self.orderSynchronizer = LocalOrderSynchronizer(siteID: siteID, stores: stores)

        configureNavigationTrailingItem()
        configureStatusBadgeViewModel()
        configureProductRowViewModels()
        configureCustomerDataViewModel()
        configurePaymentDataViewModel()
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
        configureProductRowViewModels()
    }

    /// Creates a view model for the `ProductRow` corresponding to an order item.
    ///
    func createProductRowViewModel(for item: OrderItem, canChangeQuantity: Bool) -> ProductRowViewModel? {
        guard let product = allProducts.first(where: { $0.productID == item.productID }) else {
            return nil
        }

        if item.variationID != 0, let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
            let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: product.attributes)
            return ProductRowViewModel(id: item.itemID,
                                       productVariation: variation,
                                       name: product.name,
                                       quantity: item.quantity,
                                       canChangeQuantity: canChangeQuantity,
                                       displayMode: .attributes(attributes))
        } else {
            return ProductRowViewModel(id: item.itemID, product: product, quantity: item.quantity, canChangeQuantity: canChangeQuantity)
        }
    }

    // MARK: Customer data properties

    /// Representation of customer data display properties.
    ///
    @Published private(set) var customerDataViewModel: CustomerDataViewModel = .init(billingAddress: nil, shippingAddress: nil)

    /// Creates a view model to be used in Address Form for customer address.
    ///
    func createOrderAddressFormViewModel() -> CreateOrderAddressFormViewModel {
        CreateOrderAddressFormViewModel(siteID: siteID,
                                        addressData: .init(billingAddress: orderSynchronizer.order.billingAddress,
                                                           shippingAddress: orderSynchronizer.order.shippingAddress),
                                        onAddressUpdate: { [weak self] updatedAddressData in
            let input = Self.createAddressesInput(from: updatedAddressData)
            self?.orderSynchronizer.setAddresses.send(input)
            self?.trackCustomerDetailsAdded()
        })
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
                self.onOrderCreated(newOrder)
                self.trackCreateOrderSuccess()
            case .failure(let error):
                self.notice = NoticeFactory.createOrderCreationErrorNotice()
                self.trackCreateOrderFailure(error: error)
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        trackCreateButtonTapped()
    }

    /// Assign this closure to be notified when a new order is created
    ///
    var onOrderCreated: (Order) -> Void = { _ in }

    /// Updates the order status & tracks its event
    ///
    func updateOrderStatus(newStatus: OrderStatusEnum) {
        let oldStatus = orderSynchronizer.order.status
        orderSynchronizer.setStatus.send(newStatus)
        analytics.track(event: WooAnalyticsEvent.Orders.orderStatusChange(flow: .creation, orderID: nil, from: oldStatus, to: newStatus))
    }
}

// MARK: - Types
extension NewOrderViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case none
        case create
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
                case .pending, .completed, .cancelled, .refunded, .custom:
                    return .gray(.shade5)
                case .onHold:
                    return .withColorStudio(.orange, shade: .shade5)
                case .processing:
                    return .withColorStudio(.green, shade: .shade5)
                case .failed:
                    return .withColorStudio(.red, shade: .shade5)
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
        let email: String?
        let billingAddressFormatted: String?
        let shippingAddressFormatted: String?

        init(fullName: String? = nil, email: String? = nil, billingAddressFormatted: String? = nil, shippingAddressFormatted: String? = nil) {
            self.isDataAvailable = fullName != nil || email != nil || billingAddressFormatted != nil || shippingAddressFormatted != nil
            self.fullName = fullName
            self.email = email
            self.billingAddressFormatted = billingAddressFormatted
            self.shippingAddressFormatted = shippingAddressFormatted
        }

        init(billingAddress: Address?, shippingAddress: Address?) {
            let availableFullName = billingAddress?.fullName ?? shippingAddress?.fullName

            self.init(fullName: availableFullName?.isNotEmpty == true ? availableFullName : nil,
                      email: billingAddress?.hasEmailAddress == true ? billingAddress?.email : nil,
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

        init(itemsTotal: String = "",
             shouldShowShippingTotal: Bool = false,
             shippingTotal: String = "",
             shippingMethodTitle: String = "",
             orderTotal: String = "",
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
            self.itemsTotal = currencyFormatter.formatAmount(itemsTotal) ?? ""
            self.shouldShowShippingTotal = shouldShowShippingTotal
            self.shippingTotal = currencyFormatter.formatAmount(shippingTotal) ?? ""
            self.shippingMethodTitle = shippingMethodTitle
            self.orderTotal = currencyFormatter.formatAmount(orderTotal) ?? ""
        }
    }
}

// MARK: - Helpers
private extension NewOrderViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func configureNavigationTrailingItem() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, $performingNetworkRequest)
            .map { order, performingNetworkRequest -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                guard OrderFactory.emptyNewOrder != order else {
                    return .none
                }

                return .create
            }
            .assign(to: &$navigationTrailingItem)
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
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        orderSynchronizer.setProduct.send(input)
        configureProductRowViewModels()

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: .creation))
    }

    /// Adds a selected product variation (from the product list) to the order.
    ///
    func addProductVariationToOrder(_ variation: ProductVariation) {
        let input = OrderSyncProductInput(product: .variation(variation), quantity: 1)
        orderSynchronizer.setProduct.send(input)
        configureProductRowViewModels()

        analytics.track(event: WooAnalyticsEvent.Orders.orderProductAdd(flow: .creation))
    }

    /// Configures product row view models for each item in `orderDetails`.
    ///
    func configureProductRowViewModels() {
        updateProductsResultsController()
        updateProductVariationsResultsController()
        productRows = orderSynchronizer.order.items.compactMap { item in
            guard let productRowViewModel = createProductRowViewModel(for: item, canChangeQuantity: true) else {
                return nil
            }

            // Observe changes to the product quantity
            productRowViewModel.$quantity
                .sink { [weak self] newQuantity in
                    guard let self = self, let newInput = self.createUpdateProductInput(item: item, quantity: newQuantity) else {
                        return
                    }
                    self.orderSynchronizer.setProduct.send(newInput)
                }
                .store(in: &cancellables)

            return productRowViewModel
        }
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

    /// Updates payment section view model based on items in the order.
    ///
    func configurePaymentDataViewModel() {
        orderSynchronizer.orderPublisher
            .map { [weak self] order in
                guard let self = self else {
                    return PaymentDataViewModel()
                }

                let itemsTotal = order.items
                    .map { $0.subtotal }
                    .compactMap { self.currencyFormatter.convertToDecimal(from: $0) }
                    .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

                let shippingTotal = order.shippingLines
                    .map { $0.total }
                    .compactMap { self.currencyFormatter.convertToDecimal(from: $0) }
                    .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

                let shippingMethodTitle = order.shippingLines.first?.methodTitle ?? ""

                let orderTotal = itemsTotal.adding(shippingTotal)

                return PaymentDataViewModel(itemsTotal: itemsTotal.stringValue,
                                            shouldShowShippingTotal: order.shippingLines.isNotEmpty,
                                            shippingTotal: shippingTotal.stringValue,
                                            shippingMethodTitle: shippingMethodTitle,
                                            orderTotal: orderTotal.stringValue,
                                            currencyFormatter: self.currencyFormatter)
            }
            .assign(to: &$paymentDataViewModel)
    }

    /// Tracks when customer details have been added
    ///
    func trackCustomerDetailsAdded() {
        let areAddressesDifferent: Bool = {
            guard let billingAddress = orderSynchronizer.order.billingAddress, let shippingAddress = orderSynchronizer.order.shippingAddress else {
                return false
            }
            return billingAddress != shippingAddress
        }()
        analytics.track(event: WooAnalyticsEvent.Orders.orderCustomerAdd(flow: .creation, hasDifferentShippingDetails: areAddressesDifferent))
    }

    /// Tracks when the create order button is tapped.
    ///
    /// Warning: This methods assume that `orderSynchronizer.order.items.count` is equal to the product count,
    /// As the module evolves to handle more types of items, we need to update the property to something like `itemsCount`
    /// or figure out a better way to get the product count.
    ///
    func trackCreateButtonTapped() {
        let hasCustomerDetails = orderSynchronizer.order.billingAddress != nil || orderSynchronizer.order.shippingAddress != nil
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreateButtonTapped(status: orderSynchronizer.order.status,
                                                                                productCount: orderSynchronizer.order.items.count,
                                                                                hasCustomerDetails: hasCustomerDetails))
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
}

private extension NewOrderViewModel {
    /// Fetches products from storage.
    ///
    func updateProductsResultsController() {
        do {
            try productsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for new order: \(error)")
        }
    }

    /// Fetches product variations from storage.
    ///
    func updateProductVariationsResultsController() {
        do {
            try productVariationsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching product variations for new order: \(error)")
        }
    }
}

// MARK: Constants

extension NewOrderViewModel {
    /// New Order notices
    ///
    enum NoticeFactory {
        /// Returns a default order creation error notice.
        ///
        static func createOrderCreationErrorNotice() -> Notice {
            Notice(title: Localization.errorMessage, feedbackType: .error)
        }
    }
}

private extension NewOrderViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
    }
}
