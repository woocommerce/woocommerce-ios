import Foundation
import Alamofire


/// Represents a WordPress.com Endpoint
///
struct Endpoint: URLConvertible  {

    /// WordPress.com Base URL
    ///
    let wordpressApiBaseURL = "https://public-api.wordpress.com/"

    /// WordPress.com API Version
    ///
    let wordpressApiVersion: WordPressAPIVersion

    /// Method name that should be called.
    ///
    let method: String


    /// Returns a URL instance reprensenting the current Endpoint.
    ///
    func asURL() throws -> URL {
        let path = wordpressApiBaseURL + wordpressApiVersion.path + method
        return URL(string: path)!
    }
}
