import Foundation
import Alamofire


/// Represents a WordPress.com Endpoint
///
struct DotcomEndpoint: URLConvertible  {

    /// WordPress.com Base URL
    ///
    let wordpressApiBaseURL = "https://public-api.wordpress.com/"

    /// WordPress.com API Version
    ///
    let wordpressApiVersion: WordPressAPIVersion

    /// RPC
    ///
    let path: String


    /// Returns a URL instance reprensenting the current Endpoint.
    ///
    func asURL() throws -> URL {
        return URL(string: wordpressApiBaseURL + wordpressApiVersion.path + path)!
    }
}
