import Foundation


struct Credentials {
    let authToken: String
    let userAgent: String // mmmmmmm not here
}

class OrdersRemote: Remote {

    func fetchOrders(for siteID: Int, completion: ([RemoteOrder]) -> Void) {
        let endpoint = JetpackEndpoint(wooApiVersion: .mark2, method: .get, siteID: siteID, endpoint: "orders/")

        request(endpoint: endpoint) { (payload: [String: String]) in

            NSLog("Payload: \(payload)")
        }
    }
}

struct RemoteOrder {

}
