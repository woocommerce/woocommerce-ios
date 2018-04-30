import Foundation


/// WooCommerce Order Endpoints
///
public class OrdersRemote: Remote {

    ///
    ///
    public func fetchOrders(for siteID: Int, completion: ([RemoteOrder]) -> Void) {
        let endpoint = JetpackEndpoint(wooApiVersion: .mark2, method: .get, siteID: siteID, endpoint: "orders/")

        request(endpoint: endpoint) { (response, error) in
            guard let response = response as? [String: Any] else {
                return
            }

            NSLog("Payload: \(response)")
        }
    }
}
