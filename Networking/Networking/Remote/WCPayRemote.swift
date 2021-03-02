import Foundation
import Alamofire

/// WCPay: Remote Endpoints
///
public class WCPayRemote: Remote {

    public func loadConnectionToken(for siteID: Int64,
                                    completion: @escaping(WCPayConnectionToken?, Error?) -> Void) {
        let path = "wcpay/terminal/connection_tokens"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path)
        //let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        //let request = AuthenticatedRequest(credentials: <#T##Credentials#>, request: <#T##URLRequestConvertible#>)

        let mapper = WCPayConnectionTokenMapper(siteID: siteID)

        print("Request as url request ", try! request.asURLRequest())
        print("url ", try! request.asURLRequest().url)

        enqueue(request, mapper: mapper, completion: completion)
    }

}
