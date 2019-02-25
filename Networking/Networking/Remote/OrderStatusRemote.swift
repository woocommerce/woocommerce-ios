import Foundation
import Alamofire


/// OrderStatus: Remote Endpoints
///
public final class OrderStatusRemote: Remote {

    /// Retrieves all order statuses (including custom statuses!) for a given site.
    ///
    /// - Parameters:
    ///   - siteID: site for which we'll fetch the list of order statuses.
    ///   - completion: Closure to be executed upon completion.
    ///
    func loadOrderStatuses(for siteID: Int, completion: @escaping ([OrderStatus]?, Error?) -> Void) {
        let path = Constants.orderStatusPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = OrderStatusMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
private extension OrderStatusRemote {
    enum Constants {
        static let orderStatusPath = "reports/orders/totals"
    }
}
