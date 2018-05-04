import Foundation


/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    ///
    ///
    public func fetchOrders(for siteID: Int, completion: ([RemoteOrder]) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: "orders")

        enqueue(request) { (response, error) in
            guard let parsed = response as? [String: Any] else {
                return
            }

            NSLog("Payload: \(parsed)")
        }
    }

    ///
    ///
    public func updateOrder(with orderID: String, from siteID: Int, status: String, completion: () -> Void) {
        let path = "orders/" + orderID
        let parameters = ["status": status]

        let request = JetpackRequest(wooApiVersion: .mark2, method: .post, siteID: siteID, path: path, parameters: parameters)

        enqueue(request) { (response, error) in
            guard let parsed = response as? [String: Any] else {
                return
            }

            print("Payload: \(parsed)")
        }
    }
}
