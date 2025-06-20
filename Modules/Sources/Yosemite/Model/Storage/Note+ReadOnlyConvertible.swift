import Foundation
import Storage

// Storage.Note: ReadOnlyConvertible Conformance.
//
extension Storage.Note: ReadOnlyConvertible {

    /// Updates the Storage.Note with the a ReadOnly.
    ///
    public func update(with note: Yosemite.Note) {
        let theSiteID = note.meta.identifier(forKey: .site) ?? Int.min

        siteID = Int64(theSiteID)
        noteID = note.noteID
        noteHash = Int64(note.hash)
        read = note.read
        icon = note.icon
        noticon = note.noticon
        timestamp = note.timestamp
        url = note.url
        title = note.title
        type = note.type
        subtype = note.subtype
        subject = note.subjectAsData
        header = note.headerAsData
        body = note.bodyAsData
        meta = note.metaAsData
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Note {
        return Note(noteID: noteID,
                    hash: noteHash,
                    read: read,
                    icon: icon,
                    noticon: noticon,
                    timestamp: timestamp ?? "",
                    type: type ?? "",
                    subtype: subtype,
                    url: url,
                    title: title,
                    subject: subject ?? Data(),
                    header: header ?? Data(),
                    body: body ?? Data(),
                    meta: meta ?? Data())
    }
}
