import Combine
import Foundation
import Alamofire

/// Constructs `multipart/form-data` for uploads within an HTTP or HTTPS body.
///
public protocol MultipartFormData {
    /// Appends a file with file URL for a name to form data.
    ///
    func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String)

    /// Appends data for a name to form data.
    ///
    func append(_ data: Data, withName name: String)
}

/// Defines all of the Network Operations we'll be performing. This allows us to swap the actual Wrapper in our
/// Unit Testing target, and inject mocked up responses.
///
public protocol Network {
    typealias ResponseHeaders = [String: String]

    var session: URLSession { get }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void)

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to
    /// the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: URLRequestConvertible,
                      completion: @escaping (Swift.Result<Data, Error>) -> Void)

    /// Executes a request while preserving the caller's actor isolation across the legacy network
    /// boundary.
    func responseDataAndHeaders(for request: URLRequestConvertible,
                                isolation: isolated (any Actor)?) async throws -> (Data, ResponseHeaders?)

    /// Executes the specified Network Request and returns the response body.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The response payload as `Data`.
    func responseData(for request: URLRequestConvertible,
                      isolation: isolated (any Actor)?) async throws -> Data

    /// Executes the specified Network Request. Upon completion, the payload or error will be emitted to the publisher.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///
    /// - Returns: A publisher that emits the result of the given request.
    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never>

    /// Executes the specified Network Request for file uploads. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///   - multipartFormData: Used for appending data for multipart form data uploads.
    ///   - request: Request that should be performed.
    ///   - completion: Closure to be executed upon completion.
    func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void)

    /// Whether `request` reaches the site through the Jetpack tunnel rather than directly.
    ///
    /// A request to a Jetpack site can go either way: through WordPress.com's tunnel, signed with the
    /// site's Jetpack connection, or straight to the site with an application password. Only the tunnel
    /// can fail Jetpack's signature verification, and only a tunnel success proves the connection works,
    /// so anything judging the store's Jetpack connection needs to know which path was used.
    ///
    func usesJetpackTunnel(for request: URLRequestConvertible) -> Bool
}

public extension Network {
    /// Captures the caller's actor isolation, then dispatches to the conformer's checked
    /// implementation. `callerIsolation` deliberately has a distinct label from the requirement,
    /// so every conformer must provide the required `isolation:` witness.
    func responseDataAndHeaders(for request: URLRequestConvertible,
                                callerIsolation: isolated (any Actor)? = #isolation) async throws -> (Data, ResponseHeaders?) {
        try await self.responseDataAndHeaders(for: request, isolation: callerIsolation)
    }

    /// Default implementation that returns the response body, discarding the response headers.
    func responseData(for request: URLRequestConvertible,
                      isolation: isolated (any Actor)? = #isolation) async throws -> Data {
        try await responseDataAndHeaders(for: request, isolation: isolation).0
    }
}
