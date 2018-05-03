import Foundation
import Alamofire


// TODO: Parameters Support
// TODO: RequestAdapter

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

    /// Jetpack-Tunneled RPC
    ///
    let path: String


    /// Returns a URL instance reprensenting the current Endpoint.
    ///
    func asURL() throws -> URL {
        let dotcomEndpoint = Endpoint(wordpressApiVersion: .mark1_1, path: dotcomPath(for: jetpackPath))
        return try dotcomEndpoint.asURL()
    }
}


// MARK: - Internal
//
extension JetpackEndpoint {

    /// Returns the WordPress.com Tunneling Request
    ///
    func dotcomPath(for jetpackPath: String) -> String {
        let jetpackEncodedPath = jetpackPath.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        return "jetpack-blogs/" + String(siteID) + "/rest-api/?path=" + jetpackEncodedPath + "&json=true"
    }

    /// Returns the Jetpack-Tunneled-Request's Path
    ///
    var jetpackPath: String {
        return wooApiVersion.path + path + "?_method=" + method.rawValue.lowercased()
    }
}
