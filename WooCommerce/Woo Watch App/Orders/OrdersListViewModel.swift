import Foundation
import Combine
import NetworkingWatchOS
import WooFoundationWatchOS

/// View Model for the OrdersListView
///
final class OrdersListViewModel: ObservableObject {

    /// Represent the current state of the view
    ///
    @Published private(set) var viewState = OrdersListView.State.idle

    /// Combine subs store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    private let dependencies: WatchDependencies

    init(dependencies: WatchDependencies) {
        self.dependencies = dependencies
    }

    /// Perform the initial fetch and binds the refresh trigger for further refreshes.
    ///
    @MainActor
    func fetchAndBindRefreshTrigger(trigger: AnyPublisher<Void, Never>) async {
        trigger
            .sink { [weak self] _ in
                // Do not refresh data if we are already loading it.
                guard let self, self.viewState != .loading else { return }

                Task {
                    await self.fetchOrders()
                }
            }
            .store(in: &subscriptions)

        await fetchOrders()
    }

    /// Fetch orders from a the remote source and updates the view state accordingly.
    ///
    @MainActor
    private func fetchOrders() async {

        if Self.shouldTransitionToLoading(state: viewState) {
            self.viewState = .loading
        }

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
    static func viewOrders(from remoteOrders: [Order], currencySettings: CurrencySettings) -> [OrdersListView.Order] {
        remoteOrders.map { order in
            let orderViewModel = OrderListCellViewModel(order: order, currencySettings: currencySettings)

            let items = order.items.enumerated().map { index, orderItem in
                OrdersListView.OrderItem(id: orderItem.itemID,
                                         name: orderItem.name,
                                         total: orderViewModel.total(for: orderItem),
                                         count: orderItem.quantity,
                                         showDivider: index < (order.items.count - 1) )
            }

            return OrdersListView.Order(date: orderViewModel.dateCreated,
                                        time: orderViewModel.timeCreated,
                                        number: "#\(order.number)",
                                        name: orderViewModel.customerName,
                                        total: orderViewModel.total ?? "$\(order.total)",
                                        status: orderViewModel.statusString.capitalized,
                                        email: order.billingAddress?.email ?? "",
                                        address: order.shippingAddress?.formattedPostalAddress ?? "",
                                        items: items)
        }
    }

    /// Determines when we should transition to a loading state.
    ///
    static private func shouldTransitionToLoading(state: OrdersListView.State) -> Bool {
        switch state {
        case .idle, .error:
            return true
        case .loading, .loaded: // If we have already loaded the data don't transition to a loading state.
            return false
        }
    }
}

/// Data types that feed the OrdersListView
///
extension OrdersListView {

    /// Represents the possible view states
    ///
    enum State: Equatable {
        case idle
        case loading
        case loaded(orders: [Order])
        case error
    }

    /// Represents an order.
    ///
    struct Order: Identifiable, Hashable {
        let date: String
        let time: String
        let number: String
        let name: String
        let total: String
        let status: String
        let email: String
        let address: String
        let items: [OrderItem]

        // SwiftUI ID
        var id: String {
            number
        }

        var itemCount: Int {
            items.count
        }

        /// Empty order used as a redacted placeholder.
        ///
        static let placeholder: Order = Order(date: "----",
                                              time: "----",
                                              number: "----",
                                              name: "----- -----",
                                              total: "----",
                                              status: "------- ------",
                                              email: "-----",
                                              address: "-----",
                                              items: [])
    }

    /// Represents an order item.
    ///
    struct OrderItem: Identifiable, Hashable {
        let id: Int64
        let name: String
        let total: String
        let count: Decimal
        let showDivider: Bool
    }
}
