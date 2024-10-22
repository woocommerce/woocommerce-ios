import Foundation
import Networking

/// MetaDataAction: Defines all of the Actions supported by the MetaData.
///
public enum MetaDataAction: Action {

    /// Updates metadata of a parent item both remotely and in the local database.
    ///
    /// - Parameter siteID: Site id of the item.
    /// - Parameter parentItemID: ID of the parent item.
    /// - Parameter metaDataType: Type of metadata.
    /// - Parameter metadata: Metadata to be updated.
    /// - Parameter onCompletion: Callback called when the action is finished, including the result of the update operation.
    ///
    case updateMetaData(siteID: Int64,
                        parentItemID: Int64,
                        metaDataType: MetaDataType,
                        metadata: [[String: Any?]],
                        onCompletion: (Result<[MetaData], Error>) -> Void)
}
