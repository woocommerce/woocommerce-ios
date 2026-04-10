import Foundation
import Networking


// MARK: - OrderNoteAction: Defines all of the Actions supported by the OrderNoteStore.
//
public enum OrderNoteAction: Action {
    case retrieveOrderNotes(siteID: Int64, orderID: Int64, onCompletion: ([OrderNote]?, Error?) -> Void)
    case addOrderNote(siteID: Int64, orderID: Int64, isCustomerNote: Bool, note: String, onCompletion: (OrderNote?, Error?) -> Void)
}
