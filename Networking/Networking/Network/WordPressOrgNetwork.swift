import Alamofire
import Combine
import Foundation

/// Configuration for handling cookie nonce authentication.
///
public struct CookieNonceAuthenticatorConfiguration {
    let username: String
    let password: String
    let loginURL: URL
    let adminURL: URL

    public init(username: String, password: String, loginURL: URL, adminURL: URL) {
        self.username = username
        self.password = password
        self.loginURL = loginURL
        self.adminURL = adminURL
    }
}

/// Class to handle WP.org REST API requests.
///
public final class WordPressOrgNetwork: Network {

    private let authenticator: CookieNonceAuthenticator
    private let userAgent: String?

    private lazy var alamofireSession: Alamofire.Session = {
        makeSession(configuration: .default)
    }()

    public var session: URLSession { alamofireSession.session }

    public init(configuration: CookieNonceAuthenticatorConfiguration, userAgent: String = UserAgent.defaultUserAgent) {
        self.authenticator = CookieNonceAuthenticator(configuration: configuration)
        self.userAgent = userAgent
    }

    public func responseData(for request: URLRequestConvertible) async throws -> Data? {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }

            self.alamofireSession.request(request)
                .validate()
                .responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let responseObject):
                    continuation.resume(returning: responseObject)
                case .failure(let error):
                    DDLogWarn("⚠️ Error requesting \(request.urlRequest?.url?.absoluteString ?? ""): \(error.localizedDescription)")
                    do {
                        try self.validateResponse(response.data)
                        continuation.resume(throwing: error)
                    } catch {
                        continuation.resume(throwing: error)
                    }
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
        alamofireSession.request(request)
            .validate()
            .responseData { response in
                do {
                    try self.validateResponse(response.data)
                    completion(response.value, response.networkingError)
                } catch {
                    completion(nil, error)
                }
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
        alamofireSession.request(request)
            .validate()
            .responseData { response in
                do {
                    try self.validateResponse(response.data)
                    completion(response.result.mapError { $0 })
                } catch {
                    completion(.failure(error))
                }
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
            self.alamofireSession.request(request).validate().responseData { response in
                do {
                    try self.validateResponse(response.data)
                    let result: Result<Data, Error> = response.result.mapError { $0 }
                    promise(Swift.Result.success(result))
                } catch {
                    promise(Swift.Result.success(.failure(error)))
                }
            }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        alamofireSession
            .upload(multipartFormData: multipartFormData, with: request)
            .responseData() { response in
                do {
                    try self.validateResponse(response.data)
                    completion(response.value, response.error)
                } catch {
                    completion(nil, error)
                }
            }
    }
}

private extension WordPressOrgNetwork {
    /// Creates a session manager with injected user agent and authenticator for handling cookie-nonce/token
    ///
    func makeSession(configuration sessionConfiguration: URLSessionConfiguration) -> Alamofire.Session {
        var additionalHeaders: [String: AnyObject] = [:]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }

        sessionConfiguration.httpAdditionalHeaders = additionalHeaders

        return Alamofire.Session(configuration: sessionConfiguration, interceptor: authenticator)
    }

    /// Validates whether the REST API request failed with an invalid cookie nonce.
    ///
    func validateResponse(_ data: Data?) throws {
        if let data,
           let error = try? JSONDecoder().decode(ErrorResponse.self, from: data),
           error.code == "rest_cookie_invalid_nonce" {
            throw NetworkError.invalidCookieNonce
        }
    }
}

private extension WordPressOrgNetwork {
    /// Error response for REST API requests.
    struct ErrorResponse: Decodable {
        /// Error code
        let code: String

        /// Error message
        let message: String
    }
}
