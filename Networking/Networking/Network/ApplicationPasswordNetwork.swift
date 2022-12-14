import Combine
import Foundation
import Alamofire

public class ApplicationPasswordNetwork: Network {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials

    public var session: URLSession { SessionManager.default.session }

    /// Public Initializer
    ///
    public required init(credentials: Credentials) {
        self.credentials = credentials
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
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        let request = AuthenticatedRequest(credentials: credentials, request: request)

        Alamofire.request(request).responseData { response in
            completion(response.result.toSwiftResult())
        }
    }

    @available(*, deprecated, message: "Not implemented. Use the `Result` based method instead.")
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) { }

    @available(*, deprecated, message: "Not implemented. Use the `Result` based method instead.")
    public func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        Empty<Swift.Result<Data, Error>, Never>().eraseToAnyPublisher()
    }

    @available(*, deprecated, message: "Not implemented")
    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) { }
}
