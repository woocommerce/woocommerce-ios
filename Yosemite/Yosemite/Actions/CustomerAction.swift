import Foundation

/// CustomerAction: Defines all of the Actions supported by the CustomerStore.
///
public enum CustomerAction: Action {

    /// Synchronizes all customers for the provided siteID
    ///
    case synchronizeAllCustomers(siteID: Int64, completion: (Result<Void, Error>) -> Void)
}
