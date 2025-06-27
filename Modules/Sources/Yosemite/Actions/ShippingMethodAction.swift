import Foundation

// MARK: - ShippingMethodAction: Defines all of the actions supported by the ShippingMethodStore.
//
public enum ShippingMethodAction: Action {

    /// Synchronizes all the shipping methods associated with the provided `siteID`
    ///
    case synchronizeShippingMethods(siteID: Int64, completion: (Result<Void, Error>) -> Void)
}
