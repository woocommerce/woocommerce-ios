import Foundation
import Networking


/// TaxAction: Defines all of the Actions supported by the TaxStore.
///
public enum TaxAction: Action {

    /// Retrieve and synchronizes Tax Classes matching the specified criteria.
    ///
    case retrieveTaxClasses(siteID: Int64, onCompletion: ([TaxClass]?, Error?) -> Void)

    /// Request the Tax Class found in a specified Product.
    ///
    case requestMissingTaxClasses(for: TaxClassRequestable, onCompletion: (TaxClass?, Error?) -> Void)
}
