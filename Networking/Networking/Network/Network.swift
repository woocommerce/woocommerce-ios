import Foundation
import Alamofire


/// Defines all of the Network Operations we'll be performing. This allows us to swap the actual Wrapper in our
/// Unit Testing target, and inject mocked up responses.
///
public protocol Network {

    /// Enqueues the specified Network Request.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void)
}
