import Foundation
import Alamofire


/// Site API: Remote Endpoints
///
public class SiteAPIRemote: Remote {

    /// Calls the root wp-json endpoint (`/`) via the Jetpack tunnel for the provided siteID
    /// and parses the response for API information.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the API settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadAPIInformation(for siteID: Int, completion: @escaping (SiteAPI?, Error?) -> Void) {
        let path = String()
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: path)
        let mapper = SiteAPIMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}
