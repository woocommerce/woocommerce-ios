import Foundation
import Yosemite

struct MarkOrderAsReadUseCase {
    /// Method that marks the order note as read if it is the notification for the last order.
    /// We do it in a way that first we syncronize notification to get the remote `Note`
    /// and then we compare local `orderID` with the one from remote `Note`.
    /// If they match we mark it as read.
    /// We pass syncronized note and error in the `onCompletion` completion block
    static func markOrderNoteAsReadIfNeeded(stores: StoresManager, noteID: Int64, orderID: Int, onCompletion: ((Note?, Error?) -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotification(noteID: noteID) { syncronizedNote, error in
            guard let syncronizedNote = syncronizedNote else {
                onCompletion?(nil, error)
                return
            }
            if let syncronizedNoteOrderID = syncronizedNote.orderID,
               syncronizedNoteOrderID == orderID {
                // mark as read
                let syncAction = NotificationAction.updateReadStatus(noteID: noteID, read: true) { error in
                    onCompletion?(syncronizedNote, error)
                    if let error {
                        DDLogError("⛔️ Error marking single notification as read: \(error)")
                    }
                }
                stores.dispatch(syncAction)
            }
        }
        stores.dispatch(action)
    }
}
