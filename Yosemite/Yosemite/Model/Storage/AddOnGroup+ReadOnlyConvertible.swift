import Foundation
import Storage

extension StorageAddOnGroup: ReadOnlyConvertible {
    /// Updates the receiver with a `AddOnGroup` readonly entity.
    /// Note: Relationships are not updated
    ///
    public func update(with entity: AddOnGroup) {
        siteID = entity.siteID
        groupID = entity.groupID
        name = entity.name
        priority = entity.priority
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> AddOnGroup {
        let addOnsArray: [StorageProductAddOn] = addOns?.toArray() ?? []
        return AddOnGroup(siteID: siteID,
                          groupID: groupID,
                          name: name ?? "",
                          priority: priority,
                          addOns: addOnsArray.map { $0.toReadOnly() })
    }
}
