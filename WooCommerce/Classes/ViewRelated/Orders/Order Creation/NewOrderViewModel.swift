import Yosemite

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    /// Closure to be executed when order is created
    ///
    private let onCompletion: (Order) -> Void

    /// Order to create remotely
    ///
    private var order: Order = .empty {
        didSet {
            navigationTrailingItem = .create(rendered: false)
        }
    }

    /// Active navigation bar trailing item.
    /// Defaults to an hidden (un-rendered) create button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .create(rendered: false)

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, onCompletion: @escaping (Order) -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.onCompletion = onCompletion
    }

    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case create(rendered: Bool)
        case loading
    }

    // MARK: - API Requests
    func createOrder() {
        navigationTrailingItem = .loading
        let action = OrderAction.createOrder(siteID: siteID, order: order) { [weak self] result in
            guard let self = self else { return }
            self.navigationTrailingItem = .create(rendered: true)

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
