import Foundation
import Networking

/// ProductAttributeTermAction: Defines all of the Actions supported by the ProductAttributeTermStore.
///
public enum ProductAttributeTermAction: Action {

    /// Synchronizes all ProductAttributeTerm objects for a given attribute.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nil if the operation succeed.
    ///
    case synchronizeProductAttributeTerms(siteID: Int64, attributeID: Int64, onCompletion: (Result<[ProductAttributeTerm], Error>) -> Void)
}
