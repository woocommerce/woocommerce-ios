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
        case unavailableNote
        case noNeedToMarkAsRead
    }

#if canImport(Yosemite)
    /// Async method that marks the order note as read if it is the notification for the last order.
    /// We do it in a way that first we syncronize notification to get the remote `Note`
    /// and then we compare local `orderID` with the one from remote `Note`.
    /// If they match we mark it as read.
    /// Returns syncronized note if marking was successful and error if some error happened
    static func markOrderNoteAsReadIfNeeded(stores: StoresManager, noteID: Int64, orderID: Int) async -> Result<Note, Error> {
        let syncronizedNoteResult: Result<Note, Error> = await withCheckedContinuation { continuation in
            let action = Yosemite.NotificationAction.synchronizeNotification(noteID: noteID) { syncronizedNote, error in
                guard let syncronizedNote = syncronizedNote else {
                    continuation.resume(returning: .failure(MarkOrderAsReadUseCase.Error.unavailableNote))
                    return
                }
                continuation.resume(returning: .success(syncronizedNote))
            }
            stores.dispatch(action)
        }

        switch syncronizedNoteResult {
        case .success(let syncronizedNote):
            guard let syncronizedNoteOrderID = syncronizedNote.meta.identifier(forKey: .order),
                  syncronizedNoteOrderID == orderID else {
                return .failure(MarkOrderAsReadUseCase.Error.noNeedToMarkAsRead)
            }

            let updateNoteStatusResult: Result<Note, Error> = await withCheckedContinuation { continuation in
                let syncAction = Yosemite.NotificationAction.updateReadStatus(noteID: noteID, read: true) { error in
                    if let error {
                        continuation.resume(returning: .failure(MarkOrderAsReadUseCase.Error.failure(error)))
                    } else {
                        continuation.resume(returning: .success(syncronizedNote))
                    }
                }
                stores.dispatch(syncAction)
            }

            switch updateNoteStatusResult {
            case .success(let note):
                return .success(note)
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
#endif

    /// Async method that marks the order note as read if it is the notification for the last order.
    /// We do it in a way that first we syncronize notification to get the remote `Note`
    /// and then we compare local `orderID` with the one from remote `Note`.
    /// If they match we mark it as read.
    /// Returns syncronized note id if marking was successful and error if some error happened
    static func markOrderNoteAsReadIfNeeded(network: Network, noteID: Int64, orderID: Int) async -> Result<Int64, Error> {
        let notesRemote = NotificationsRemote(network: network)

        let loadedNotes: Result<[Note], Error> = await withCheckedContinuation { continuation in
            notesRemote.loadNotes(noteIDs: [noteID], pageSize: nil) { result in
                switch result {
                case .success(let notes):
                    continuation.resume(returning: .success(notes))
                case .failure(let error):
                    continuation.resume(returning: .failure(MarkOrderAsReadUseCase.Error.failure(error)))
                }
            }
        }

        switch loadedNotes {
        case .success(let notes):
            guard let note = notes.first else {
                return .failure(MarkOrderAsReadUseCase.Error.unavailableNote)
            }
            guard let syncronizedNoteOrderID = note.meta.identifier(forKey: .order),
               syncronizedNoteOrderID == orderID else {
                return .failure(MarkOrderAsReadUseCase.Error.noNeedToMarkAsRead)
            }

            let updatedStatus: Result<Int64, Error> = await withCheckedContinuation { continuation in
                notesRemote.updateReadStatus(noteIDs: [noteID], read: true) { error in
                    if let error {
                        continuation.resume(returning: .failure(MarkOrderAsReadUseCase.Error.failure(error)))
                    } else {
                        continuation.resume(returning: .success(noteID))
                    }
                }
            }

            switch updatedStatus {
            case .success(let noteID):
                return .success(noteID)
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
