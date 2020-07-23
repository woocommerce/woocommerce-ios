import Foundation
import Networking


// MARK: - ProductVariationAction: Defines all of the Actions supported by the ProductVariationStore.
//
public enum ProductVariationAction: Action {

    /// Synchronizes the ProductVariation's matching the specified criteria.
    ///
    case synchronizeProductVariations(siteID: Int64, productID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Updates a specified ProductVariation.
    ///
    case updateProductVariation(productVariation: ProductVariation, onCompletion: (Result<ProductVariation, ProductUpdateError>) -> Void)
}
