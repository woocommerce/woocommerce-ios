import Foundation
import Networking

/// ProductAttributeTermAction: Defines all of the Actions supported by the ProductAttributeTermStore.
///
public enum ProductAttributeTermAction: Action {

    /// Synchronizes all ProductAttributeTerm objects for a given attribute.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nil if the operation succeed.
    ///
    case synchronizeProductAttributeTerms(siteID: Int64, attributeID: Int64, onCompletion: (Result<Void, ProductAttributeTermActionError>) -> Void)

    /// Create a new product attribute term associated with a given `Site ID` and `attribute ID`.
    /// `onCompletion` will be invoked when the add operation finishes.
    ///
    case createProductAttributeTerm(siteID: Int64, attributeID: Int64, name: String, onCompletion: (Result<ProductAttributeTerm, Error>) -> Void)
}

/// Defines all errors that a `ProductAttributeTermAction` can return
///
public enum ProductAttributeTermActionError: Error {
    /// Represents the product attribute term synchronization failed state.
    ///
    case termsSynchronization(pageNumber: Int, rawError: Error)
}
