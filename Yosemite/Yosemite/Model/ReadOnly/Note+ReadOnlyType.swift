import Foundation
import Storage


// MARK: - Yosemite.Note: ReadOnlyType
//
extension Yosemite.Note: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageNote = storageEntity as? Storage.Note else {
            return false
        }

        return storageNote.noteID == noteID
    }
}
