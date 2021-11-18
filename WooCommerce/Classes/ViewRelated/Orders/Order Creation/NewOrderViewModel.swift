import Yosemite

/// View model for `NewOrder`.
///
final class NewOrderViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    /// New order to create remotely
    ///
    private var order: Order = .empty {
        didSet {
            // Adding details to the order makes the Create button visible
            navigationTrailingItem = .create
        }
    }

    /// Active navigation bar trailing item.
    /// Defaults to no visible button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .none

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case none
        case create
        case loading
    }

    // MARK: - API Requests
    func createOrder() {
        navigationTrailingItem = .loading
        let action = OrderAction.createOrder(siteID: siteID, order: order) { [weak self] result in
            guard let self = self else { return }
            self.navigationTrailingItem = .create

            switch result {
            case .success:
                // TODO: Handle newly created order / remove success logging
                DDLogInfo("New order created successfully!")
            case .failure(let error):
                // TODO: Display error in the UI (#5457)
                DDLogError("⛔️ Error creating new order: \(error)")
            }
        }
        stores.dispatch(action)
    }
}
