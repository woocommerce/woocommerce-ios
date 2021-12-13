import Foundation

// MARK: - DataAction: Defines the actions that allows you to view all types of data available.
// API: https://woocommerce.github.io/woocommerce-rest-api-docs/#data
//
public enum DataAction: Action {

    /// Retrieves countries from the site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the countries from.
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case synchronizeCountries(siteID: Int64,
                              onCompletion: (Result<[Country], Error>) -> Void)
}
