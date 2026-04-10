import Foundation
import Networking


// MARK: - OrderFulfillmentAction: Defines all of the Actions supported by the OrderFulfillmentStore.
//
public enum OrderFulfillmentAction: Action {

    /// Synchronizes all the fulfillment data associated with the provided `siteID` and `orderID`.
    ///
    case synchronizeOrderFulfillments(siteID: Int64, orderID: Int64, onCompletion: (Error?) -> Void)
}
