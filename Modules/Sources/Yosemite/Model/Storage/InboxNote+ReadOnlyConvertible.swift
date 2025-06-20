import Foundation
import Storage


// MARK: - Storage.InboxNote: ReadOnlyConvertible
//
extension Storage.InboxNote: ReadOnlyConvertible {

    /// Updates the `Storage.InboxNote` from the ReadOnly representation (`Networking.InboxNote`)
    ///
    public func update(with inboxNote: Yosemite.InboxNote) {
        siteID = inboxNote.siteID
        id = inboxNote.id
        name = inboxNote.name
        type = inboxNote.type
        status = inboxNote.status
        title = inboxNote.title
        content = inboxNote.content
        isRemoved = inboxNote.isRemoved
        isRead = inboxNote.isRead
        dateCreated = inboxNote.dateCreated
    }

    /// Returns a ReadOnly (`Networking.InboxNote`) version of the `Storage.InboxNote`
    ///
    public func toReadOnly() -> Yosemite.InboxNote {
        return Yosemite.InboxNote(siteID: siteID,
                                  id: id,
                                  name: name ?? "",
                                  type: type ?? "",
                                  status: status ?? "",
                                  actions: actions?.map { $0.toReadOnly() } ?? [Yosemite.InboxAction](),
                                  title: title ?? "",
                                  content: content ?? "",
                                  isRemoved: isRemoved,
                                  isRead: isRead,
                                  dateCreated: dateCreated ?? Date())
    }
}
