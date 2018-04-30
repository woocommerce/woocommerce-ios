import Foundation
import Alamofire

// TODO: Parameters Encoding

/// Represents a Jetpack-Tunneled WordPress.com Endpoint: Tunnels the RPC call via /jetpack-blogs/$site/rest-api/
///
struct JetpackEndpoint: URLConvertible  {

    /// WooCommerce API Version
    ///
    let wooApiVersion: WooAPIVersion

    /// Jetpack-Tunneled HTTP Request Method
    ///
    let method: HTTPMethod

    /// Jetpack-Tunneled Site ID
    ///
    let siteID: Int

    /// Jetpack-Tunneled Endpoint name!
    ///
    let endpoint: String


    /// Returns a URL instance reprensenting the current Endpoint.
    ///
    func asURL() throws -> URL {
        let tunneledEndpoint = wooApiVersion.path + endpoint + "&_method=" + method.rawValue.lowercased()
        guard let encodedPath  = tunneledEndpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            fatalError()
        }

        let dotcomMethod = "jetpack-blogs/" + String(siteID) + "/rest-api/?path=" + encodedPath + "&json=true"
        let dotcomEndpoint = Endpoint(wordpressApiVersion: .mark1_1, method: dotcomMethod)

        return try dotcomEndpoint.asURL()

    }
}
