import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif

#if canImport(Yosemite)
import Yosemite
#endif

struct MarkOrderAsReadUseCase {
    /// Possible error states.
    ///
    enum Error: Swift.Error {
        case failure(Swift.Error)
        case updateReadStatus(Swift.Error)
        case unavailableNote
    }
    /// Method that marks the order note as read if it is the notification for the last order.
    /// We do it in a way that first we syncronize notification to get the remote `Note`
    /// and then we compare local `orderID` with the one from remote `Note`.
    /// If they match we mark it as read.
    /// We pass syncronized note and error in the `onCompletion` completion block
#if canImport(Yosemite)
    static func markOrderNoteAsReadIfNeeded(stores: StoresManager, noteID: Int64, orderID: Int, onCompletion: ((Note?, Error?) -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotification(noteID: noteID) { syncronizedNote, error in
            guard let syncronizedNote = syncronizedNote else {
                onCompletion?(nil, MarkOrderAsReadUseCase.Error.unavailableNote)
                return
            }
            if let syncronizedNoteOrderID = syncronizedNote.meta.identifier(forKey: .order),
               syncronizedNoteOrderID == orderID {
                // mark as read
                let syncAction = NotificationAction.updateReadStatus(noteID: noteID, read: true) { error in
                    if let error {
                        onCompletion?(nil, MarkOrderAsReadUseCase.Error.failure(error))
                    } else {
                        onCompletion?(syncronizedNote, nil)
                    }
                }
                stores.dispatch(syncAction)
            }
        }
        stores.dispatch(action)
    }
#endif
    /// Method that marks the order note as read if it is the notification for the last order.
    /// We do it in a way that first we syncronize notification to get the remote `Note`
    /// and then we compare local `orderID` with the one from remote `Note`.
    /// If they match we mark it as read.
    /// We pass syncronized note id and error in the `onCompletion` completion block
    static func markOrderNoteAsReadIfNeeded(network: Network, noteID: Int64, orderID: Int, onCompletion: ((Int64?, Error?) -> Void)? = nil) {
        // use notifications remote
        let notesRemote = NotificationsRemote(network: network)
        notesRemote.loadNotes(noteIDs: [noteID], pageSize: nil) { result in
            switch result {
            case .success(let notes):
                if let note = notes.first {
                    if let syncronizedNoteOrderID = note.meta.identifier(forKey: .order),
                       syncronizedNoteOrderID == orderID {
                        notesRemote.updateReadStatus(noteIDs: [noteID], read: true) { error in
                            if let error {
                                onCompletion?(nil, MarkOrderAsReadUseCase.Error.updateReadStatus(error))
                            } else {
                                onCompletion?(noteID, nil)
                            }
                        }
                    }
                } else {
                    onCompletion?(nil, MarkOrderAsReadUseCase.Error.unavailableNote)
                }
            case .failure(let error):
                onCompletion?(nil, MarkOrderAsReadUseCase.Error.failure(error))
            }
        }
    }
}
