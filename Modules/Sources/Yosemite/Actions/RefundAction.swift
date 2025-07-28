import Foundation
import Networking


/// RefundAction: Defines all of the Actions supported by the RefundStore.
///
public enum RefundAction: Action {
    case createRefund(siteID: Int64, orderID: Int64, refund: Refund, onCompletion: (Refund?, Error?) -> Void)
    case retrieveRefund(siteID: Int64, orderID: Int64, refundID: Int64, onCompletion: (Refund?, Error?) -> Void)
    case retrieveRefunds(siteID: Int64, orderID: Int64, refundIDs: [Int64], deleteStaleRefunds: Bool, onCompletion: (Error?) -> Void)
    case synchronizeRefunds(siteID: Int64, orderID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)
    case resetStoredRefunds(onCompletion: () -> Void)
}
