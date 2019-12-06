import Foundation
import Networking


/// TaxClassesAction: Defines all of the Actions supported by the TaxClassesStore.
///
public enum TaxClassesAction: Action {

    /// Retrieve and synchronizes Tax Classes matching the specified criteria.
    ///
    case retriveTaxClasses(siteID: Int, onCompletion: (Error?) -> Void)

    /// Deletes all of the cached tax classes.
    ///
    case resetStoredTaxClasses(onCompletion: () -> Void)

    /// Request the Tax Class found in a specified Product.
    ///
    case requestMissingTaxClasses(for: Product, onCompletion: (Error?) -> Void)
}
