import Foundation
import Storage


// MARK: - Yosemite.ProductVariation: ReadOnlyType
//
extension Yosemite.ProductVariation: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageProductVariation = storageEntity as? Storage.ProductVariation else {
            return false
        }

        return siteID == Int(storageProductVariation.siteID) &&
            productID == Int(storageProductVariation.productID) &&
            variationID == Int(storageProductVariation.variationID)
    }
}
