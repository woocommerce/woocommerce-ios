import Foundation
import Storage


// MARK: - Yosemite.Product: ReadOnlyType
//
extension Yosemite.Product: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageProduct = storageEntity as? Storage.Product else {
            return false
        }

        return siteID == Int(storageProduct.siteID) && productID == Int(storageProduct.productID)
    }
}
