import Foundation
import Networking


/// RefundAction: Defines all of the Actions supported by the RefundStore.
///
public enum RefundAction: Action {
    case createRefund(siteID: Int, orderID: Int, refund: Refund, onCompletion: (Refund?, Error?) -> Void)
    case retrieveRefund(siteID: Int, orderID: Int, refundID: Int, onCompletion: (Refund?, Error?) -> Void)
    case retrieveRefunds(siteID: Int, orderID: Int, refundIDs: [Int], onCompletion: (Error?) -> Void)
    case synchronizeRefunds(siteID: Int, orderID: Int, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)
    case resetStoredRefunds(onCompletion: () -> Void)
}
