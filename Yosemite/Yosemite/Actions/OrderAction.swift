import Foundation
import Networking



// MARK: - OrderAction: Defines all of the Actions supported by the OrderStore.
//
public enum OrderAction: Action {
    case retrieveOrders(siteID: Int, onCompletion: ([Order]?, Error?) -> Void)
    case retrieveOrder(siteID: Int, orderID: Int, onCompletion: (Order?, Error?) -> Void)
    case updateOrder(siteID: Int, orderID: Int, status: OrderStatus, onCompletion: (Order?, Error?) -> Void)
}
