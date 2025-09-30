import NetworkingCore

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
        network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        ordersRemote = OrdersRemote(network: network)
    }

    /// Fetches orders for a store ID.
    ///
    func loadAllOrders(for storeID: Int64, pageNumber: Int, pageSize: Int) async throws -> [Order] {
        try await ordersRemote.loadAllOrders(for: storeID, pageNumber: pageNumber, pageSize: pageSize)
    }
}
