import Foundation
import Storage


// MARK: - Storage.OrderMetaData: ReadOnlyConvertible
//
extension Storage.OrderMetaData: ReadOnlyConvertible {

    /// Updates the Storage.OrderMetaData with the ReadOnly.
    ///
    public func update(with orderMetaData: Yosemite.OrderMetaData) {
        metadataID = orderMetaData.metadataID
        key = orderMetaData.key
        value = orderMetaData.value
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderMetaData {
        return OrderMetaData(metadataID: metadataID,
                             key: key ?? "",
                             value: value ?? "")
    }
}
