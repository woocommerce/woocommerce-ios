import Yosemite

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let noticePresenter: NoticePresenter

    /// Active navigation bar trailing item.
    /// Defaults to no visible button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .none

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.siteID = siteID
        self.stores = stores
        self.noticePresenter = noticePresenter
    }

    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case none
        case create
        case loading
    }

    // MARK: - API Requests
    /// Creates an order remotely using the provided order details.
    ///
    func createOrder() {
        navigationTrailingItem = .loading
        let order = prepareOrderForRemote()

        let action = OrderAction.createOrder(siteID: siteID, order: order) { [weak self] result in
            guard let self = self else { return }
            self.navigationTrailingItem = .create

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
    /// Prepares the order to send to the remote endpoint, using the provided order details.
    ///
    /// Add order details here to include them in the remote order creation request.
    ///
    func prepareOrderForRemote() -> Order {
        Order.empty.copy(siteID: siteID)
    }

    /// Enqueues the `Error creating new order` Notice.
    ///
    private func displayOrderCreationErrorNotice() {
        let message = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
        let notice = Notice(title: message, feedbackType: .error)

        noticePresenter.enqueue(notice: notice)
    }
}
