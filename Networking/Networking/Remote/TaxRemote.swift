import Foundation

/// Tax Class: Remote Endpoints
///
public class TaxRemote: Remote {

    // MARK: - Tax Class

    /// Retrieves all of the `Tax Classes` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote tax classes.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllTaxClasses(for siteID: Int64,
                                completion: @escaping ([TaxClass]?, Error?) -> Void) {

        let path = Path.taxes + "/classes"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = TaxClassListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `Tax Classes` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote tax classes.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveTaxRates(siteID: Int64,
                                 pageNumber: Int,
                                 pageSize: Int,
                                 onCompletion: @escaping (Result<[TaxRate], Error>) -> Void) {

        let path = Path.taxes
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: [
                                        ParameterKeys.page: String(pageNumber),
                                        ParameterKeys.perPage: String(pageSize)],
                                     availableAsRESTRequest: true)
        let mapper = TaxRateListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: onCompletion)
    }

    /// Retrieves the tax rate identified by the tax rate id
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote tax classes.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveTaxRate(siteID: Int64,
                                taxRateID: Int64,
                                onCompletion: @escaping (Result<TaxRate, Error>) -> Void) {

        let path = "\(Path.taxes)/\(taxRateID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = TaxRateMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

// MARK: - Constants
//
public extension TaxRemote {

    private enum Path {
        static let taxes   = "taxes"
    }

    private enum ParameterKeys {
        static let page: String             = "page"
        static let perPage: String          = "per_page"
    }
}
