import Combine
import Foundation

/// Implementation of the `Network` protocol, following the
/// [Null object pattern](https://en.wikipedia.org/wiki/Null_object_pattern)
/// It does nothing at all.
///
public final class NullNetwork: Network {

    public var session: URLSession { URLSession(configuration: .default) }

    public init() { }

    public func responseData(for request: Request, completion: @escaping (Data?, Error?) -> Void) { }

    public func responseData(for request: Request,
                             completion: @escaping (Swift.Result<Data, Error>) -> Void) {

    }

    public func responseDataPublisher(for request: Request) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        Empty<Swift.Result<Data, Error>, Never>().eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: Request,
                                        completion: @escaping (Data?, Error?) -> Void) { }
}
