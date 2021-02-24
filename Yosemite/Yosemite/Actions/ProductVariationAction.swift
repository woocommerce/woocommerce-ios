import Foundation
import Networking


// MARK: - ProductVariationAction: Defines all of the Actions supported by the ProductVariationStore.
//
public enum ProductVariationAction: Action {

    /// Synchronizes the ProductVariation's matching the specified criteria.
    ///
    case synchronizeProductVariations(siteID: Int64, productID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified ProductVariation.
    ///
    case retrieveProductVariation(siteID: Int64, productID: Int64, variationID: Int64, onCompletion: (Result<ProductVariation, Error>) -> Void)

    /// Create a new ProductVariation.
    ///
    case createProductVariation(siteID: Int64,
                                 productID: Int64,
                                 newVariation: CreateProductVariation,
                                 onCompletion: (Result<ProductVariation, Error>) -> Void)

    /// Updates a specified ProductVariation.
    ///
    case updateProductVariation(productVariation: ProductVariation, onCompletion: (Result<ProductVariation, ProductUpdateError>) -> Void)

    /// Requests the variations in a specified Order that have not been fetched.
    ///
    case requestMissingVariations(for: Order, onCompletion: (Error?) -> Void)

    /// Delete an existing ProductVariation.
    ///
    case deleteProductVariation(productVariation: ProductVariation, onCompletion: (Result<Void, ProductUpdateError>) -> Void)
}
