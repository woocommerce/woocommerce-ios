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
                                 onCompletion: @escaping (Result<([TaxRate]), Error>) -> Void) {

        let path = Path.taxes
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = TaxRateListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

// MARK: - Constants
//
public extension TaxRemote {

    private enum Path {
        static let taxes   = "taxes"
    }
}
