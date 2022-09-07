import Alamofire
import Combine
import Foundation
import WordPressKit

/// Class to handle WP.org REST API requests.
///
public final class WordPressOrgNetwork: Network {

    private let authenticator: Authenticator?
    private let userAgent: String?

    private lazy var sessionManager: Alamofire.SessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    private lazy var backgroundSessionManager: Alamofire.SessionManager = {
        // A unique ID is included in the background session identifier so that the session does not get invalidated when the initializer is called multiple
        // times (e.g. when logging in).
        let uniqueID = UUID().uuidString
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.automattic.woocommerce.backgroundsession.\(uniqueID)")
        let sessionManager = makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    public init(authenticator: Authenticator? = nil, userAgent: String? = nil) {
        self.authenticator = authenticator
        self.userAgent = userAgent
    }

    public func responseData(for request: URLRequestConvertible) async throws -> Data? {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }

            self.sessionManager.request(request)
                .validate()
                .responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let responseObject):
                    continuation.resume(returning: responseObject)
                case .failure(let error):
                    DDLogWarn("⚠️ Error requesting \(request.urlRequest?.url?.absoluteString ?? ""): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }

            })
        }
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Important:
    ///     - User agent and authenticator from the initializer will be injected through the `validate` call.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        sessionManager.request(request)
            .validate()
            .responseData { response in
                completion(response.value, response.networkingError)
            }
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Important:
    ///     - User agent and authenticator from the initializer will be injected through the `validate` call..
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

    /// Executes the specified Network Request. Upon completion, the payload or error will be emitted to the publisher.
    /// Only one value will be emitted and the request cannot be retried.
    ///
    /// - Important:
    ///     - User agent and authenticator from the initializer will be injected through the `validate` call..
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: A publisher that emits the result of the given request.
    public func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        return Future() { [weak self] promise in
            guard let self = self else { return }
            self.sessionManager.request(request).validate().responseData { response in
                let result = response.result.toSwiftResult()
                promise(Swift.Result.success(result))
            }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        backgroundSessionManager.upload(multipartFormData: multipartFormData, with: request) { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseData { response in
                    completion(response.value, response.error)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}

private extension WordPressOrgNetwork {
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
