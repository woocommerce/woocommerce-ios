import Foundation
import Alamofire

/// Tax Classes: Remote Endpoints
///
public class TaxClassesRemote: Remote {

    // MARK: - Tax Classes
    
    /// Retrieves all of the `Tax Classes` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote tax classes.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllTaxClasses(for siteID: Int,
                                completion: @escaping ([TaxClass]?, Error?) -> Void) {

        let path = Path.taxes + "/classes"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = TaxClassListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants
//
public extension TaxClassesRemote {

    private enum Path {
        static let taxes   = "taxes"
    }
}
