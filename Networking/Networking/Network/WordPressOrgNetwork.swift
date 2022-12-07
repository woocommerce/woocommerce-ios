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

    private var nonce: String?
    private let configuration: CookieNonceAuthenticatorConfiguration

    private let sessionManager: SessionManager = .default

    public var session: URLSession { sessionManager.session }

    public init(configuration: CookieNonceAuthenticatorConfiguration) {
        self.configuration = configuration
    }

    public func responseData(for request: Request) async throws -> Data? {
        let request = try await createRequest(wrapping: request)
        let data = try await sessionManager.request(request)
        return data
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseData(for request: Request, completion: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let request = try await createRequest(wrapping: request)
                let data = try await sessionManager.request(request)
                await MainActor.run {
                    completion(data, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func responseData(for request: Request, completion: @escaping (Result<Data, Error>) -> Void) {
        Task {
            do {
                let request = try await createRequest(wrapping: request)
                let data = try await sessionManager.request(request)
                await MainActor.run {
                    completion(.success(data))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Executes the specified Network Request. Upon completion, the payload or error will be emitted to the publisher.
    /// Only one value will be emitted and the request cannot be retried.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: A publisher that emits the result of the given request.
    public func responseDataPublisher(for request: Request) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        return Future() { promise in
            Task {
                do {
                    let request = try await self.createRequest(wrapping: request)
                    let data = try await self.sessionManager.request(request)
                    await MainActor.run {
                        promise(Result.success(.success(data)))
                    }
                } catch {
                    await MainActor.run {
                        promise(Result.success(.failure(error)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormDataType) -> Void,
                                        to request: Request,
                                        completion: @escaping (Data?, Error?) -> Void) {
        Task {
            let request = try await createRequest(wrapping: request)
            do {
                let data = try await sessionManager.upload(multipartFormData: multipartFormData, with: request)
                await MainActor.run {
                    completion(data, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }
}

private extension WordPressOrgNetwork {
    func createRequest(wrapping request: Request) async throws -> Request {
        try await handleLoginAndNonceRetrieval()
        guard let nonce else {
            throw NetworkError.nonceAuthenticationFailed
        }
        var adaptedRequest = try request.asURLRequest()
        adaptedRequest.addValue(nonce, forHTTPHeaderField: "X-WP-Nonce")
        return adaptedRequest
    }

    func handleLoginAndNonceRetrieval() async throws {
        guard nonce == nil else {
            return // No need to log in again
        }
        DDLogInfo("Starting Cookie+Nonce login sequence for \(configuration.loginURL)")
        guard let nonceRetrievalURL = URL(string: "admin-ajax.php?action=rest-nonce", relativeTo: configuration.adminURL) else {
            throw NetworkError.nonceAuthenticationFailed
        }
        let request = authenticatedRequest(redirectURL: nonceRetrievalURL)
        let (data, _) = try await session.data(for: request)

        DDLogInfo("Posted Login to \(configuration.loginURL), redirected to \(nonceRetrievalURL)")
        guard let page = String(data: data, encoding: .utf8),
              let nonce = readNonceFromAjaxAction(html: page) else {
            throw NetworkError.nonceAuthenticationFailed
        }
        self.nonce = nonce
    }

    func readNonceFromAjaxAction(html: String) -> String? {
        guard !html.isEmpty else {
            return nil
        }
        return html
    }

    func authenticatedRequest(redirectURL: URL) -> URLRequest {
        var request = URLRequest(url: configuration.loginURL)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: configuration.username))
        parameters.append(URLQueryItem(name: "pwd", value: configuration.password))
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        parameters.append(URLQueryItem(name: "redirect_to", value: redirectURL.absoluteString))
        var components = URLComponents()
        components.queryItems = parameters
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        return request
    }
}
