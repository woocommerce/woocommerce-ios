import Combine
import Foundation

/// Defines all of the Network Operations we'll be performing. This allows us to swap the actual Wrapper in our
/// Unit Testing target, and inject mocked up responses.
///
public protocol Network {

    var session: URLSession { get }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: Request, completion: @escaping (Data?, Error?) -> Void)

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to
    /// the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: Request,
                      completion: @escaping (Swift.Result<Data, Error>) -> Void)

    /// Executes the specified Network Request. Upon completion, the payload or error will be emitted to the publisher.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///
    /// - Returns: A publisher that emits the result of the given request.
    func responseDataPublisher(for request: Request) -> AnyPublisher<Swift.Result<Data, Error>, Never>

    /// Executes the specified Network Request for file uploads. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///   - multipartFormData: Used for appending data for multipart form data uploads.
    ///   - request: Request that should be performed.
    ///   - completion: Closure to be executed upon completion.
    func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormDataType) -> Void,
                                 to request: Request,
                                 completion: @escaping (Data?, Error?) -> Void)
}
