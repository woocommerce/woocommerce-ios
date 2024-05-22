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

    /// Fetch orders from a the remote source and updates the view state accordingly.
    ///
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

    /// Convert remote orders into view orders.
    ///
    private static func viewOrders(from remoteOrders: [Order], currencySettings: CurrencySettings) -> [OrdersListView.Order] {
        remoteOrders.map { order in
            // TODO: Provide real list of site statuses.
            let orderViewModel = OrderListCellViewModel(order: order, status: nil, currencySettings: currencySettings)
            return OrdersListView.Order(date: orderViewModel.dateCreated,
                                        number: "#\(order.number)",
                                        name: orderViewModel.customerName,
                                        price: orderViewModel.total ?? "$\(order.total)",
                                        status: orderViewModel.statusString.capitalized)
        }
    }
}

/// Data types that feed the OrdersListView
///
extension OrdersListView {

    /// Represents the possible view states
    ///
    enum State {
        case idle
        case loading
        case loaded(orders: [Order])
        case error
    }

    /// Represents an order item.
    ///
    struct Order: Identifiable, Hashable {
        let date: String
        let number: String
        let name: String
        let price: String
        let status: String

        // SwiftUI ID
        var id: String {
            number
        }
    }
}
