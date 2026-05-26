import Foundation


/// OrderFulfillmentsRemote: Remote Endpoints
///
public final class OrderFulfillmentsRemote: Remote {

    /// Retrieves all fulfillments for a given order.
    ///
    /// - Parameters:
    ///   - siteID: Site which hosts the Order
    ///   - orderID: Identifier of the Order
    ///   - completion: Closure to be executed upon completion
    ///
    public func loadOrderFulfillments(for siteID: Int64,
                                      orderID: Int64,
                                      completion: @escaping ([OrderFulfillment]?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/\(orderID)/\(Constants.fulfillmentsPath)"

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = OrderFulfillmentListMapper(siteID: siteID, orderID: orderID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
private extension OrderFulfillmentsRemote {

    enum Constants {
        static let ordersPath = "orders"
        static let fulfillmentsPath = "fulfillments"
    }
}
