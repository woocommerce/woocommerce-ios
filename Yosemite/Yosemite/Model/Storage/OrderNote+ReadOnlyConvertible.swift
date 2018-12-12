import Foundation
import Storage


// MARK: - Storage.OrderNote: ReadOnlyConvertible
//
extension Storage.OrderNote: ReadOnlyConvertible {

    /// Updates the Storage.OrderCoupon with the ReadOnly.
    ///
    public func update(with orderNote: Yosemite.OrderNote) {
        noteID = Int64(orderNote.noteID)
        dateCreated = orderNote.dateCreated
        note = orderNote.note
        isCustomerNote = orderNote.isCustomerNote
        author = orderNote.author
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderNote {
        return OrderNote(noteId: Int(noteID),
                         dateCreated: dateCreated ?? Date(),
                         note: note ?? "",
                         isCustomerNote: isCustomerNote,
                         author: author ?? "")
    }
}
