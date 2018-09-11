import Foundation
import Networking



// MARK: - OrderAction: Defines all of the Actions supported by the OrderStore.
//
public enum OrderAction: Action {
    case synchronizeOrders(siteID: Int, page: Int, size: Int, onCompletion: (Error?) -> Void)
    case retrieveOrder(siteID: Int, orderID: Int, onCompletion: (Order?, Error?) -> Void)
    case updateOrder(siteID: Int, orderID: Int, status: OrderStatus, onCompletion: (Error?) -> Void)
}
