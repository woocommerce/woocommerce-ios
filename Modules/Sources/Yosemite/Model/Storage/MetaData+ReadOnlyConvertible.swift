import Foundation
import Storage


// MARK: - Storage.MetaData: ReadOnlyConvertible
//
extension Storage.MetaData: ReadOnlyConvertible {

    /// Updates the Storage.MetaData with the ReadOnly.
    ///
    public func update(with metaData: Yosemite.MetaData) {
        metadataID = metaData.metadataID
        key = metaData.key
        value = metaData.value.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.MetaData {
        return MetaData(metadataID: metadataID,
                             key: key ?? "",
                             value: value ?? "")
    }
}


// MARK: - Storage.MetaData: ListItemConvertible
//
extension Storage.MetaData: ListItemConvertible {
    public func toListItem() -> Yosemite.MetaData {
        return toReadOnly()
    }
}
