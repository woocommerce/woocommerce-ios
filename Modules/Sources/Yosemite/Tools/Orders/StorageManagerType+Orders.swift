import Foundation
import protocol Storage.StorageManagerType

public extension StorageManagerType {
    /// Whether an order with the given identifiers currently exists in the view storage.
    ///
    func containsStoredOrder(siteID: Int64, orderID: Int64) -> Bool {
        viewStorage.loadOrder(siteID: siteID, orderID: orderID) != nil
    }
}
