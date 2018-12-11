import Foundation
import Storage


// MARK: - Yosemite.OrderNote: ReadOnlyType
//
extension Yosemite.OrderNote: ReadOnlyType {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageOrderNote = storageEntity as? Storage.OrderNote else {
            return false
        }

        return noteID == Int(storageOrderNote.noteID)
    }
}
