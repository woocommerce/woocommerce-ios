import Foundation
import Alamofire


/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    /// Retrieves all of the `Orders` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllOrders(for siteID: Int, completion: @escaping ([Order]?, Error?) -> Void) {
        let path = "orders"
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path)
        let mapper = OrderListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the `OrderStatus` of a given Order.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order to be updated.
    ///     - status: New Status to be set.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateOrder(from siteID: Int, with orderID: String, status: String, completion: @escaping (Error?) -> Void) {
        let path = "orders/" + orderID
        let parameters = ["status": status]

        let request = JetpackRequest(wooApiVersion: .mark2, method: .post, siteID: siteID, path: path, parameters: parameters)
        enqueue(request) { (_, error) in
            completion(error)
        }
    }
}
