import NetworkingWatchOS

/// This wrapper to fetch orders resources.
///
final class OrdersDataService {

    /// Orders remote
    ///
    private let ordersRemote: OrdersRemote

    /// Network helper.
    ///
    private let network: AlamofireNetwork

    init(credentials: Credentials) {
        network = AlamofireNetwork(credentials: credentials)
        ordersRemote = OrdersRemote(network: network)
    }

    /// Async wrapper that fetches orders for a store ID.
    ///
    func loadAllOrders(for storeID: Int64, pageNumber: Int, pageSize: Int) async throws -> [Order] {
        try await withCheckedThrowingContinuation { continuation in
            ordersRemote.loadAllOrders(for: storeID, pageNumber: pageNumber, pageSize: pageSize) { result in
                continuation.resume(with: result)
            }
        }
    }
}
