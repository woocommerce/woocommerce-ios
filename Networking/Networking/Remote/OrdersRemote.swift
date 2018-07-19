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
    public func loadAllOrders(for siteID: Int, page: Int = 1, completion: @escaping ([Order]?, Error?) -> Void) {
        let path = Constants.ordersPath
        let parameters = [ParameterKeys.page: String(page),
                          ParameterKeys.perPage: String(Constants.defaultPageSize)]
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `Order`
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadOrder(for siteID: Int, orderID: Int, completion: @escaping (Order?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = OrderMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves the notes for a specific `Order`
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadOrderNotes(for siteID: Int, orderID: Int, completion: @escaping ([OrderNote]?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/\(orderID)/\(Constants.notesPath)/"
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = OrderNotesMapper()

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
    public func updateOrder(from siteID: Int, orderID: Int, status: String, completion: @escaping (Order?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/" + String(orderID)
        let parameters = [ParameterKeys.status: status]
        let mapper = OrderMapper(siteID: siteID)

        let request = JetpackRequest(wooApiVersion: .mark2, method: .post, siteID: siteID, path: path, parameters: parameters)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension OrdersRemote {
    enum Constants {
        static let defaultPageSize: Int     = 75
        static let ordersPath: String       = "orders"
        static let notesPath: String        = "notes"
    }

    enum ParameterKeys {
        static let status: String   = "status"
        static let page: String     = "page"
        static let perPage: String  = "per_page"
    }
}
