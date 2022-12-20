import Alamofire
import Combine
import Foundation
import WordPressKit
/// This Network is specific for generating and deleting application passwords
///
///  - We cannot use the AlamofireNetwork as we will be initiating the application password generation from there. (By listening to other API calls)
///  - Uses WPOrg credentials to fetch the application password
///
public class ApplicationPasswordNetwork: Network {
    private let authenticator: Authenticator?
    private let userAgent: String?

    private lazy var sessionManager: Alamofire.SessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    public var session: URLSession { SessionManager.default.session }

    /// Public Initializer
    ///
    @MainActor
    public init(authenticator: Authenticator? = nil, userAgent: String = UserAgent.defaultUserAgent) {
        self.authenticator = authenticator
        self.userAgent = userAgent
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
        sessionManager.request(request)
            .validate()
            .responseData { response in
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

private extension ApplicationPasswordNetwork {
    /// Creates a session manager with injected user agent and authenticator for handling cookie-nonce/token
    ///
    func makeSessionManager(configuration sessionConfiguration: URLSessionConfiguration) -> Alamofire.SessionManager {
        var additionalHeaders: [String: AnyObject] = [:]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }

        sessionConfiguration.httpAdditionalHeaders = additionalHeaders

        let sessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        sessionManager.adapter = authenticator
        sessionManager.retrier = authenticator
        return sessionManager
    }
}
