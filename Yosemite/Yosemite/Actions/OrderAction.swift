import Foundation
import Networking



// MARK: - Public Aliases
//
public typealias Order = Networking.Order


// MARK: - OrderAction: Defines all of the Actions supported by the OrderStore.
//
public enum OrderAction: Action {
    case retrieveOrders(siteID: Int, onCompletion: ([Order]?, Error?) -> Void)
}
