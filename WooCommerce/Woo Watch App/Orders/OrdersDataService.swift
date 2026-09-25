import NetworkingCore

/// This wrapper to fetch orders resources.
///
final class OrdersDataService: Sendable {
    private let credentials: Credentials

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    /// Fetches orders for a store ID.
    ///
    func loadAllOrders(for storeID: Int64, pageNumber: Int, pageSize: Int) async throws -> [Order] {
        // Keep the non-Sendable networking objects local to this request.
        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        let ordersRemote = OrdersRemote(network: network)
        return try await ordersRemote.loadAllOrders(for: storeID, pageNumber: pageNumber, pageSize: pageSize)
    }
}
