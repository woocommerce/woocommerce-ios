import Foundation
import Alamofire


/// Defines all of the Network Operations we'll be performing. This allows us to swap the actual Wrapper in our
/// Unit Testing target, and inject mocked up responses.
///
public protocol Network {

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - credentials: WordPress.com Credentials.
    ///
    init(credentials: Credentials)

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void)
}
