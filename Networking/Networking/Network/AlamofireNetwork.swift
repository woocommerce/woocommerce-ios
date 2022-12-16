import Combine
import Foundation
import Alamofire

extension Alamofire.MultipartFormData: MultipartFormData {}

/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials?

    private let backgroundSessionManager: Alamofire.SessionManager

    /// Authenticator to update requests authorization header if possible.
    ///
    private let requestAuthenticator: RequestAuthenticator

    public var session: URLSession { SessionManager.default.session }

    /// Public Initializer
    ///
    public required init(credentials: Credentials?) {
        self.credentials = credentials
        self.requestAuthenticator = RequestAuthenticator(credentials: credentials)

        // A unique ID is included in the background session identifier so that the session does not get invalidated when the initializer is called multiple
        // times (e.g. when logging in).
        let uniqueID = UUID().uuidString
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.automattic.woocommerce.backgroundsession.\(uniqueID)")
        self.backgroundSessionManager = Alamofire.SessionManager(configuration: configuration)
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
        requestAuthenticator.authenticateRequest(request) { result in
            switch result {
            case .success(let request):
                Alamofire.request(request)
                    .responseData { response in
                        completion(response.value, response.networkingError)
                    }
            case .failure(let error):
                completion(nil, error)
            }
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
        requestAuthenticator.authenticateRequest(request) { result in
            switch result {
            case .success(let request):
                Alamofire.request(request).responseData { response in
                    completion(response.result.toSwiftResult())
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Executes the specified Network Request. Upon completion, the payload or error will be emitted to the publisher.
    /// Only one value will be emitted and the request cannot be retried.
    ///
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Network's Credentials.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: A publisher that emits the result of the given request.
    public func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        return Future() { promise in
            self.requestAuthenticator.authenticateRequest(request) { result in
                switch result {
                case .success(let request):
                    Alamofire.request(request).responseData { response in
                        let result = response.result.toSwiftResult()
                        promise(.success(result))
                    }
                case .failure(let error):
                    promise(.success(.failure(error)))
                }
            }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        requestAuthenticator.authenticateRequest(request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let request):
                self.backgroundSessionManager.upload(multipartFormData: multipartFormData, with: request) { (encodingResult) in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseData { response in
                            completion(response.value, response.error)
                        }
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}

public extension AlamofireNetwork {
    /// Updates the application password use case with a new site ID.
    ///
    func configureApplicationPasswordHandler(with siteID: Int64) {
        guard let credentials else {
            return
        }
        let applicationPasswordUseCase = TemporaryApplicationPasswordUseCase(siteID: siteID, credentials: credentials)
        requestAuthenticator.updateApplicationPasswordHandler(with: applicationPasswordUseCase)
    }
}


// MARK: - Alamofire.DataResponse: Helper Methods
//
extension Alamofire.DataResponse {

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
//
extension Alamofire.Result {
    /// Convert this `Alamofire.Result` to a `Swift.Result`.
    ///
    func toSwiftResult() -> Swift.Result<Value, Error> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
