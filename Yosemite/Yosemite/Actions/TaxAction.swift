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

    /// Retrieve and synchronizes Tax Rates matching the specified criteria.
    ///
    case retrieveTaxRates(siteID: Int64,
                          pageNumber: Int,
                          pageSize: Int,
                          onCompletion: (Result<[TaxRate], Error>) -> Void)

    /// Retrieves the specified Tax Rate.
    ///
    case retrieveTaxRate(siteID: Int64, taxRateID: Int64, onCompletion: (Result<TaxRate, Error>) -> Void)
}
