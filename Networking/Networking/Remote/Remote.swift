import Foundation
import Alamofire


/// Represents a collection of Remote Endpoints
///
public class Remote {

    /// WordPress.com Credentials
    ///
    let credentials: Credentials

    /// Designated Initializer.
    ///
    /// - Parameter credentials: Credentials to be used in order to authenticate every request.
    ///
    public init(credentials: Credentials) {
        self.credentials = credentials
    }

    /// Returns the HTTPHeaders containing our Authorization Token.
    ///
    var headers: HTTPHeaders {
        return [
            "Authorization": "Bearer \(credentials.authToken)",
            "Accept": "application/json",
            "User-Agent": Settings.userAgent
        ]
    }

    /// Submits a request over the Network!
    ///
    /// - Parameters:
    ///     - endpoint: Remote Endpoint that should be queried.
    ///     - method: HTTP Method to use.
    ///     - completion: Closure to be executed upon completion.
    ///
    func request(endpoint: URLConvertible, method: HTTPMethod = .get, completion: @escaping (Any?, Error?) -> Void) {
        Alamofire.request(endpoint, method: method, headers: headers)
            .validate()
            .responseJSON { response in
                completion(response.result.value, response.result.error)
        }
    }
}
