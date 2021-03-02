import Foundation
import Alamofire

/// WCPay: Remote Endpoints
///
public class WCPayRemote: Remote {

    /// Loads a WCPay connection token for a given site ID and parses the rsponse
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the WCPay Connection token.
    ///   - completion: Closure to be executed upon completion.
    public func loadConnectionToken(for siteID: Int64,
                                    completion: @escaping(WCPayConnectionToken?, Error?) -> Void) {
        let path = "payments/connection_tokens"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path)

        let mapper = WCPayConnectionTokenMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}
