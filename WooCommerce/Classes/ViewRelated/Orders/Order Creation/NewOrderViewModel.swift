import Yosemite
import Combine

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let noticePresenter: NoticePresenter

    /// Order details used to create the order
    ///
    @Published var orderDetails = OrderDetails()

    /// Active navigation bar trailing item.
    /// Defaults to no visible button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .none

    /// Tracks if a network request is being performed.
    ///
    @Published var performingNetworkRequest = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.siteID = siteID
        self.stores = stores
        self.noticePresenter = noticePresenter

        configureNavigationTrailingItem()
    }

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
                self.displayOrderCreationErrorNotice()
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        stores.dispatch(action)
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

    /// Enqueues the `Error creating new order` Notice.
    ///
    private func displayOrderCreationErrorNotice() {
        let message = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
        let notice = Notice(title: message, feedbackType: .error)

        noticePresenter.enqueue(notice: notice)
    }
}
