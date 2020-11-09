import Foundation
import Alamofire


extension Alamofire.MultipartFormData: MultipartFormData {
    public func append(_ data: Data, withName name: String) {

    }
}

/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {

    private let sessionManager: Alamofire.Session

    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials


    /// Public Initializer
    ///
    public required init(credentials: Credentials) {
        self.credentials = credentials

        let configuration = URLSessionConfiguration.default
        self.sessionManager = Alamofire.Session(configuration: configuration)
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
    /// - Note:
    ///     - The response body will always be returned (when possible), even when there's a networking error.
    ///       This differs slightly from the standard Alamofire `.validate()` behavior, and it's required so that
    ///       the upper layers can properly detect "Jetpack Tunnel" Errors.
    ///     - Yes. We do the above because the Jetpack Tunnel endpoint doesn't properly relay the correct statusCode.
    ///
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)

        AF.request(authenticated)
            .responseData { response in
                completion(response.value, response.networkingError)
            }
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
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)

        AF.request(authenticated).responseData { response in
            completion(response.result.toSwiftResult())
        }
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)


        _ = sessionManager.upload(multipartFormData: multipartFormData, with: authenticated).responseData(completionHandler: { (response) in
            switch response.result {
            case .success(let data):
                completion(data, response.error)
            case .failure(let error):
                completion(nil, error)
            }
        })
    }
}


/// MARK: - Alamofire.DataResponse: Private Methods
///
private extension Alamofire.DataResponse {

    /// Returns the Networking Layer Error (if any):
    ///
    ///     -   Whenever the statusCode is not within the [200, 300) range.
    ///     -   Whenever there's a `NSURLErrorDomain` error: Bad Certificate, Unreachable, Cancelled (and few others!)
    ///
    /// NOTE: that we're not doing the standard Alamofire Validation, because the stock routine, on error, will never relay
    /// back the response body. And since the Jetpack Tunneling API does not relay the proper statusCodes, we're left in
    /// the dark.
    ///
    /// Precisely: Request Timeout should be a 408, but we just get a 400, with the details in the response's body.
    ///
    var networkingError: Error? {

        // Passthru URL Errors: These are right there, even without calling Alamofire's validation.
        if let error = error as NSError?, error.domain == NSURLErrorDomain {
            return error
        }

        return response.flatMap { response in
            NetworkError(from: response.statusCode)
        }
    }
}

// MARK: - Swift.Result Conversion

private extension Swift.Result where Success == Data, Failure == AFError {
    /// Convert this `Swift.Result<Data, AFError>` to a `Swift.Result<Data, Error>`.
    ///
    func toSwiftResult() -> Swift.Result<Data, Error> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
