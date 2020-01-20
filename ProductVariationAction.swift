// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import Networking

// MARK: - ProductVariationAction: Defines all of the Actions supported by the ProductVariationStore.
//
public enum ProductVariationAction: Action {

    /// Synchronizes the ProductVariation's matching the specified criteria.
    ///
    case synchronizeProductVariationModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified ProductVariation.
    ///
    case retrieveProductVariation(siteID: Int64, remoteID: Int64, onCompletion: (ProductVariation?, Error?) -> Void)
}
