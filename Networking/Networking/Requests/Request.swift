import Foundation

public protocol Request {
    /// Returns a URL request or throws if an `Error` was encountered.
    ///
    /// - throws: An `Error` if the underlying `URLRequest` is `nil`.
    ///
    /// - returns: A URL request.
    func asURLRequest() throws -> URLRequest

    /// Returns a closure that tries to parse a response looking for an error
    ///
    func responseDataValidator() -> ResponseDataValidator
}

/// Makes URLRequest conform to Request
///
extension URLRequest: Request {
    public func asURLRequest() throws -> URLRequest {
        return self
    }
}

/// Default implementation
///
extension Request {
    public func responseDataValidator() -> ResponseDataValidator {
        DummyValidator()
    }
}

/// WordPress.com Response Validator
///
struct DummyValidator: ResponseDataValidator {
    /// A dummy validator to bypass requirement for data validator in `Request` types by default
    ///
    func validate(data: Data) throws {
        // no-op
    }
}
