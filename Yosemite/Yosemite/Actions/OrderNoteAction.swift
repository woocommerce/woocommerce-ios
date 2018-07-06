import Foundation
import Networking


// MARK: - OrderNoteAction: Defines all of the Actions supported by the OrderNoteStore.
//
public enum OrderNoteAction: Action {
    case retrieveOrderNotes(siteID: Int, orderID: Int, onCompletion: ([OrderNote]?, Error?) -> Void)
}
