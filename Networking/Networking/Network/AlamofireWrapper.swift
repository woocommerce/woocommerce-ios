import Foundation
import Alamofire


/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public struct AlamofireWrapper: Network {

    /// Public Initializer
    ///
    public init() {
    }

    /// Executes the specified Network Request. Upon completion, the payload will be parsed as JSON, and sent back to the caller.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseJSON(for request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        Alamofire.request(request)
            .validate()
            .responseJSON { response in
                completion(response.result.value, response.result.error)
        }
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        Alamofire.request(request)
            .validate()
            .responseData { response in
                completion(response.result.value, response.result.error)
        }
    }
}
