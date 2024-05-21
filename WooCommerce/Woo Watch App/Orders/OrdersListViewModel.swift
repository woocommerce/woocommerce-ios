import Foundation
import NetworkingWatchOS

/// View Model for the OrdersListView
///
final class OrdersListViewModel: ObservableObject {

    private let dependencies: WatchDependencies

    init(dependencies: WatchDependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func fetchOrders() async {
        let service = OrdersDataService(credentials: dependencies.credentials)
        do {
            let orders = try await service.loadAllOrders(for: dependencies.storeID, pageNumber: 1, pageSize: 50)
            print(orders)
        } catch {
            DDLogError("⛔️ Error fetching orders. \(error)")
        }
    }
}
