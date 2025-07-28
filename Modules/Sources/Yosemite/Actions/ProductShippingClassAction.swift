import Foundation
import Networking

// MARK: - ProductShippingClassAction: Defines all of the Actions supported by the ProductShippingClassStore.
//
public enum ProductShippingClassAction: Action {

    /// Synchronizes the ProductShippingClass's matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more shipping classes to sync.
    ///
    case synchronizeProductShippingClassModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Result<Bool, Error>) -> Void)

    /// Retrieves the specified ProductShippingClass.
    ///
    case retrieveProductShippingClass(siteID: Int64, remoteID: Int64, onCompletion: (ProductShippingClass?, Error?) -> Void)
}
