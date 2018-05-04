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


    /// Enqueues a given Network Request.
    ///
    /// - Parameters:
    ///     - url: Request that should be executed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func request(endpoint: URLConvertible, method: HTTPMethod = .get, completion: @escaping (Any?, Error?) -> Void) {
        Alamofire.request(endpoint, method: method)
            .validate()
            .responseJSON { response in
                completion(response.result.value, response.result.error)
        }
    }

    ///
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)

        Alamofire.request(authenticated)
            .validate()
            .responseJSON { response in
                completion(response.result.value, response.result.error)
        }
    }
}
