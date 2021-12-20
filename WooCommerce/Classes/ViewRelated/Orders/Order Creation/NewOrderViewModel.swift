import Yosemite
import Combine
import protocol Storage.StorageManagerType

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    private var cancellables: Set<AnyCancellable> = []

    /// Order details used to create the order
    ///
    @Published var orderDetails = OrderDetails()

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
    @Published var presentNotice: NewOrderNotice?

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

    /// Assign this closure to be notified when a new order is created
    ///
    var onOrderCreated: (Order) -> Void = { _ in }

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

    /// View model for the product list
    ///
    lazy var addProductViewModel = {
        AddProductToOrderViewModel(siteID: siteID, storageManager: storageManager, stores: stores) { [weak self] product in
            guard let self = self else { return }
            self.addProductToOrder(product)
        }
    }()

    /// View models for each product row in the order.
    ///
    @Published private(set) var productRows: [ProductRowViewModel] = []

    /// Item selected from the list of products in the order.
    /// Used to open the product details in `ProductInOrder`.
    ///
    @Published var selectedOrderItem: NewOrderItem? = nil

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager

        configureNavigationTrailingItem()
        configureStatusBadgeViewModel()
        configureProductRowViewModels()
    }

    /// Selects an order item.
    ///
    /// - Parameter id: ID of the order item to select
    func selectOrderItem(_ id: String) {
        selectedOrderItem = orderDetails.items.first(where: { $0.id == id })
    }

    /// Removes an item from the order.
    ///
    /// - Parameter item: Item to remove from the order
    func removeItemFromOrder(_ item: NewOrderItem) {
        orderDetails.items.removeAll(where: { $0 == item })
        configureProductRowViewModels()
    }

    // MARK: - API Requests
    /// Creates an order remotely using the provided order details.
    ///
    func createOrder() {
        performingNetworkRequest = true

        let action = OrderAction.createOrder(siteID: siteID, order: orderDetails.toOrder()) { [weak self] result in
            guard let self = self else { return }
            self.performingNetworkRequest = false

            switch result {
            case .success(let newOrder):
                // TODO: Handle newly created order / remove success logging
                DDLogInfo("New order created successfully!")
                self.onOrderCreated(newOrder)
            case .failure(let error):
                self.presentNotice = .error
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        stores.dispatch(action)
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

    /// Type to hold all order detail values
    ///
    struct OrderDetails {
        var status: OrderStatusEnum = .pending
        var items: [NewOrderItem] = []
        var billingAddress: Address?
        var shippingAddress: Address?

        /// Used to create `Order` and check if order details have changed from empty/default values.
        /// Required because `Order` has `Date` properties that have to be the same to be Equatable.
        ///
        let emptyOrder = Order.empty

        func toOrder() -> Order {
            emptyOrder.copy(status: status,
                            items: items.map { $0.orderItem },
                            billingAddress: billingAddress,
                            shippingAddress: shippingAddress)
        }
    }

    /// Representation of possible notices that can be displayed
    ///
    enum NewOrderNotice {
        case error
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

    /// Representation of new items in an order.
    ///
    struct NewOrderItem: Equatable, Identifiable {
        var id: String
        let product: Product
        var quantity: Decimal

        var orderItem: OrderItem {
            product.toOrderItem(quantity: quantity)
        }

        init(product: Product, quantity: Decimal) {
            self.id = UUID().uuidString
            self.product = product
            self.quantity = quantity
        }
    }
}

// MARK: - Helpers
private extension NewOrderViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func configureNavigationTrailingItem() {
        Publishers.CombineLatest($orderDetails, $performingNetworkRequest)
            .map { orderDetails, performingNetworkRequest -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                guard orderDetails.emptyOrder != orderDetails.toOrder() else {
                    return .none
                }

                return .create
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Updates status badge viewmodel based on status order property.
    ///
    func configureStatusBadgeViewModel() {
        $orderDetails
            .map { [weak self] orderDetails in
                guard let siteOrderStatus = self?.currentSiteStatuses.first(where: { $0.status == orderDetails.status }) else {
                    return StatusBadgeViewModel(orderStatusEnum: orderDetails.status)
                }
                return StatusBadgeViewModel(orderStatus: siteOrderStatus)
            }
            .assign(to: &$statusBadgeViewModel)
    }

    /// Adds a selected product (from the product list) to the order.
    ///
    func addProductToOrder(_ product: Product) {
        let newOrderItem = NewOrderItem(product: product, quantity: 1)
        orderDetails.items.append(newOrderItem)
        configureProductRowViewModels()
    }

    /// Configures product row view models for each item in `orderDetails`.
    ///
    func configureProductRowViewModels() {
        productRows = orderDetails.items.enumerated().map { index, item in
            let productRowViewModel = ProductRowViewModel(id: item.id, product: item.product, canChangeQuantity: true)

            // Observe changes to the product quantity
            productRowViewModel.$quantity
                .sink { [weak self] newQuantity in
                    self?.orderDetails.items[index].quantity = newQuantity
                }
                .store(in: &cancellables)

            return productRowViewModel
        }
    }
}
