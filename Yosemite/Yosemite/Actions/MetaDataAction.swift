import Foundation
import Networking

/// MetaDataAction: Defines all of the Actions supported by the MetaData.
///
public enum MetaDataAction: Action {

    /// Updates order metadata both remotely and in the local database.
    ///
    /// - Parameter siteID: Site id of the order.
    /// - Parameter orderID: ID of the order.
    /// - Parameter metadata: Metadata to be updated.
    /// - Parameter onCompletion: Callback called when the action is finished, including the result of the update operation.
    ///
    case updateOrderMetaData(siteID: Int64,
                             orderID: Int64,
                             metadata: [[String: Any?]],
                             onCompletion: (Result<[MetaData], Error>) -> Void)

    /// Updates product metadata both remotely and in the local database.
    ///
    /// - Parameter siteID: Site id of the product.
    /// - Parameter productID: ID of the product.
    /// - Parameter metadata: Metadata to be updated.
    /// - Parameter onCompletion: Callback called when the action is finished, including the result of the update operation.
    ///
    case updateProductMetaData(siteID: Int64,
                               productID: Int64,
                               metadata: [[String: Any?]],
                               onCompletion: (Result<[MetaData], Error>) -> Void)
}
