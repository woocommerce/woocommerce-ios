import Foundation
import Storage

// Storage.Note: ReadOnlyConvertible Conformance.
//
extension Storage.Note: ReadOnlyConvertible {

    /// Updates the Storage.Note with the a ReadOnly.
    ///
    public func update(with note: Yosemite.Note) {
        noteID = Int64(note.noteId)
        noteHash = Int64(note.hash)
        read = note.read
        icon = note.icon
        noticon = note.noticon
        timestamp = note.timestamp
        url = note.url
        title = note.title
        subject = note.subjectAsData
        header = note.headerAsData
        body = note.bodyAsData
        meta = note.metaAsData
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Note {
        return Note(noteId: noteID,
                    hash: noteHash,
                    read: read,
                    icon: icon,
                    noticon: noticon,
                    timestamp: timestamp ?? "",
                    type: type ?? "",
                    url: url,
                    title: title,
                    subject: subject,
                    header: header,
                    body: body,
                    meta: meta)
    }
}
