import Foundation
import Alamofire

/// Implementation of the `Network` protocol, following the
/// [Null object pattern](https://en.wikipedia.org/wiki/Null_object_pattern)
/// It does nothing at all.
///
public final class NullNetwork: Network {
    public init() { }
    public required init(credentials: Credentials) { }

    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) { }

    public func responseData(for request: URLRequestConvertible,
                             completion: @escaping (Swift.Result<Data, Error>) -> Void) {

    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) { }
}
