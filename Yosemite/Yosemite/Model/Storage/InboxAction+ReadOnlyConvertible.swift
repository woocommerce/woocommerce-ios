import Foundation
import Storage


// MARK: - Storage.InboxAction: ReadOnlyConvertible
//
extension Storage.InboxAction: ReadOnlyConvertible {

    /// Updates the Storage.InboxAction with the ReadOnly.
    ///
    public func update(with inboxAction: Yosemite.InboxAction) {
        id = inboxAction.id
        name = inboxAction.name
        label = inboxAction.label
        status = inboxAction.status
        url = inboxAction.url
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.InboxAction {
        return InboxAction(id: id,
                           name: name ?? "",
                           label: label ?? "",
                           status: status ?? "",
                           url: url ?? "")
    }
}
