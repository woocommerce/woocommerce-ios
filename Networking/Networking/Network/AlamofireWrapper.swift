import Foundation
import Alamofire


/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public struct AlamofireWrapper: Network {

    /// Public Initializer
    ///
    public init() {
    }

    /// Enqueues the specified Network Request.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        Alamofire.request(request)
            .validate()
            .responseJSON { response in
                completion(response.result.value, response.result.error)
        }
    }
}
