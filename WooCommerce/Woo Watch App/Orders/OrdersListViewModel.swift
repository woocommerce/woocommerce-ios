import Foundation
import NetworkingWatchOS
import WooFoundationWatchOS

/// View Model for the OrdersListView
///
final class OrdersListViewModel: ObservableObject {

    /// Represent the current state of the view
    ///
    @Published private(set) var viewState = OrdersListView.State.idle

    private let dependencies: WatchDependencies

    init(dependencies: WatchDependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func fetchOrders() async {
        self.viewState = .loading
        let service = OrdersDataService(credentials: dependencies.credentials)
        do {
            let orders = try await service.loadAllOrders(for: dependencies.storeID, pageNumber: 1, pageSize: 50)
            let viewOrders = Self.viewOrders(from: orders, currencySettings: dependencies.currencySettings)
            self.viewState = .loaded(orders: viewOrders)
        } catch {
            self.viewState = .error
            DDLogError("⛔️ Error fetching orders. \(error)")
        }
    }

    private static func viewOrders(from remoteOrders: [Order], currencySettings: CurrencySettings) -> [OrdersListView.Order] {
        remoteOrders.map { order in
            OrdersListView.Order(date: order.dateCreated.description,
                                 number: "#\(order.number)",
                                 name: ((order.billingAddress?.firstName ?? "") + " " + (order.billingAddress?.lastName ?? "")),
                                 price: "$\(order.total)",
                                 status: order.status.rawValue)
        }
    }
}


extension OrdersListView {

    enum State {
        case idle
        case loading
        case loaded(orders: [Order])
        case error
    }

    struct Order {
        let date: String
        let number: String
        let name: String
        let price: String
        let status: String
    }
}
