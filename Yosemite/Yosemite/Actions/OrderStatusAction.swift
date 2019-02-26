import Foundation
import Networking


// MARK: - OrderStatusAction: Defines all of the Actions supported by the OrderStatusStore.
//
public enum OrderStatusAction: Action {
    case retrieveOrderStatuses(siteID: Int, onCompletion: (Error?) -> Void)
}
