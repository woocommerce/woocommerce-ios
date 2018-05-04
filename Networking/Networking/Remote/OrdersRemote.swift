import Foundation


/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    /// NOTE: This is a Stub. To be completed + Unit Tested in a second PR.
    ///
    public func fetchOrders(for siteID: Int, completion: @escaping ([RemoteOrder]) -> Void) {
        let path = "orders"
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path)

        enqueue(request) { (response, error) in
            guard let parsed = response as? [String: Any] else {
                return
            }

            print("Payload: \(parsed)")
            completion([])
        }
    }

    /// NOTE: This is a Stub. To be completed + Unit Tested in a second PR.
    ///
    public func updateOrder(with orderID: String, from siteID: Int, status: String, completion: @escaping () -> Void) {
        let path = "orders/" + orderID
        let parameters = ["status": status]

        let request = JetpackRequest(wooApiVersion: .mark2, method: .post, siteID: siteID, path: path, parameters: parameters)

        enqueue(request) { (response, error) in
            guard let parsed = response as? [String: Any] else {
                return
            }

            print("Payload: \(parsed)")
            completion()
        }
    }
}
