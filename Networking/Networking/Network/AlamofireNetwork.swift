import Foundation
import Alamofire


/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {

    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials


    /// Public Initializer
    ///
    public required init(credentials: Credentials) {
        self.credentials = credentials
    }

    /// Executes the specified Network Request. Upon completion, the payload will be parsed as JSON, and sent back to the caller.
    ///
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Network's Credentials.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseJSON(for request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)

        Alamofire.request(authenticated)
            .validate()
            .responseJSON { response in
                completion(response.value, response.customizedError)
            }
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Network's Credentials.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)

        Alamofire.request(authenticated)
            .validate()
            .responseData { response in
                completion(response.value, response.customizedError)
            }
    }
}


/// MARK: - Alamofire.DataResponse: Private Methods
///
private extension Alamofire.DataResponse {

    /// Returns `NetworkError.notFound` whenever the Request failed  with a 404 StatusCode. This may be used by upper layers,
    /// to determine if an object should be deleted (for instance!).
    ///
    /// In any other case, this property will actually return the regular `DataResponse.error` result.
    ///
    var customizedError: Error? {
        guard result.isFailure else {
            return nil
        }

        guard response?.statusCode == HTTPStatusCode.notFound else {
            return error
        }

        return NetworkError.notFound
    }
}
