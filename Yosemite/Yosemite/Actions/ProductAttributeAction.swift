import Foundation
import Networking

/// ProductAttributeAction: Defines all of the Actions supported by the ProductAttributeStore.
///
public enum ProductAttributeAction: Action {

    /// Synchronizes all ProductAttributes.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nil if the operation succeed.
    ///
    case synchronizeProductAttributes(siteID: Int64, onCompletion: (Result<[ProductAttribute], Error>) -> Void)

    /// Create a new global product attribute associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nill if the operation succeed.
    ///
    case addProductAttribute(siteID: Int64, name: String, onCompletion: (Result<ProductAttribute, Error>) -> Void)

    /// Update an existing global product attribute associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nill if the operation succeed.
    ///
    case updateProductAttribute(siteID: Int64,
                                productAttributeID: Int64,
                                name: String,
                                onCompletion: (Result<ProductAttribute, Error>) -> Void)

    /// Delete a global product attribute associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nill if the operation succeed.
    ///
    case deleteProductAttribute(siteID: Int64, productAttributeID: Int64, onCompletion: (Result<ProductAttribute, Error>) -> Void)
}
