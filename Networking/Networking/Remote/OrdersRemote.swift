import Foundation
import Alamofire


/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    /// NOTE: This is a Stub. To be completed + Unit Tested in a second PR.
    ///
    public func loadAllOrders(for siteID: Int, completion: @escaping ([Order]?, Error?) -> Void) {
        let path = "orders"
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path)
        let mapper = OrderListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// NOTE: This is a Stub. To be completed + Unit Tested in a second PR.
    ///
    public func updateOrder(with orderID: String, from siteID: Int, status: String, completion: @escaping (Error?) -> Void) {
        let path = "orders/" + orderID
        let parameters = ["status": status]

        let request = JetpackRequest(wooApiVersion: .mark2, method: .post, siteID: siteID, path: path, parameters: parameters)
        enqueue(request) { (_, error) in
            completion(error)
        }
    }
}
