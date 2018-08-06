import Foundation
import Storage


// MARK: - Storage.OrderNote: ReadOnlyConvertible
//
extension Storage.OrderNote: ReadOnlyConvertible {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func represents(readOnlyEntity: Any) -> Bool {
        guard let readOnlyNote = readOnlyEntity as? Yosemite.OrderNote else {
            return false
        }

// TODO: Add order.orderID + order.siteID Check
        return readOnlyNote.noteID == Int(noteID)
    }

    /// Updates the Storage.OrderCoupon with the ReadOnly.
    ///
    public func update(with orderNote: Yosemite.OrderNote) {
        noteID = Int64(orderNote.noteID)
        dateCreated = orderNote.dateCreated
        note = orderNote.note
        isCustomerNote = orderNote.isCustomerNote
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderNote {
        return OrderNote(noteId: Int(noteID),
                         dateCreated: dateCreated ?? Date(),
                         note: note ?? "",
                         isCustomerNote: isCustomerNote)
    }
}
