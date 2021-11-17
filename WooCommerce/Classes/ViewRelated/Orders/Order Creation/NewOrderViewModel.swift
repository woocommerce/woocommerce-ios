import Yosemite

/// View model for `NewOrder`.
///
final class NewOrderViewModel {
    private let siteID: Int64
    private let stores: StoresManager

    /// Closure to be executed when order is created
    ///
    private let onCompletion: (Order) -> Void

    /// Order to create remotely
    ///
    private var order: Order = .empty {
        didSet {
            isCreateButtonEnabled = true
        }
    }

    /// Whether to enable the Create button
    ///
    private(set) var isCreateButtonEnabled: Bool = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, onCompletion: @escaping (Order) -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.onCompletion = onCompletion
    }

    // MARK: - API Requests
    func createOrder() {
        let action = OrderAction.createOrder(siteID: siteID, order: order) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let order):
                self.onCompletion(order)
            case .failure(let error):
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        stores.dispatch(action)
    }
}
