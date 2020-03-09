import Foundation
import Networking

// MARK: - ProductShippingClassAction: Defines all of the Actions supported by the ProductShippingClassStore.
//
public enum ProductShippingClassAction: Action {

    /// Synchronizes the ProductShippingClass's matching the specified criteria.
    ///
    case synchronizeProductShippingClassModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified ProductShippingClass.
    ///
    case retrieveProductShippingClass(siteID: Int64, remoteID: Int64, onCompletion: (ProductShippingClass?, Error?) -> Void)
}
