import Yosemite
import Combine

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager

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

    // MARK: - Products Section Properties

    /// Products added to the order
    ///
    private(set) var selectedProducts: [Product] = []

    /// View models for each product row in the order
    ///
    var productRowViewModels: [ProductRowViewModel] {
        selectedProducts.map { .init(product: $0, canChangeQuantity: true) }
    }

    // MARK: - Initialization

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        configureNavigationTrailingItem()
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
            case .success:
                // TODO: Handle newly created order / remove success logging
                DDLogInfo("New order created successfully!")
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
        var products: [OrderItem] = []
        var billingAddress: Address?
        var shippingAddress: Address?

        /// Used to create `Order` and check if order details have changed from empty/default values.
        /// Required because `Order` has `Date` properties that have to be the same to be Equatable.
        ///
        let emptyOrder = Order.empty

        func toOrder() -> Order {
            emptyOrder.copy(status: status,
                            items: products,
                            billingAddress: billingAddress,
                            shippingAddress: shippingAddress)
        }
    }

    /// Representation of possible notices that can be displayed
    ///
    enum NewOrderNotice {
        case error
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
}
