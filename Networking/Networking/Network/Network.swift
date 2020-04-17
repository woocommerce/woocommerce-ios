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

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - credentials: WordPress.com Credentials.
    ///
    init(credentials: Credentials)

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void)

    /// Executes the specified Network Request for file uploads. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Parameters:
    ///   - multipartFormData: Used for appending data for multipart form data uploads.
    ///   - request: Request that should be performed.
    ///   - completion: Closure to be executed upon completion.
    func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void)
}
