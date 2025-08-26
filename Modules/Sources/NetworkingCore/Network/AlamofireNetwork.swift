import Combine
import Foundation
import Alamofire

/// Helper type to observe selected site info
public struct JetpackSite: Equatable {
    let siteID: Int64
    let siteAddress: String
    let applicationPasswordAvailable: Bool

    public init(siteID: Int64, siteAddress: String, applicationPasswordAvailable: Bool) {
        self.siteID = siteID
        self.siteAddress = siteAddress
        self.applicationPasswordAvailable = applicationPasswordAvailable
    }
}

/// Extension to observe default store ID and address
/// The values are set in the UI layer (`SessionManager`).
/// Ensure the keys are in synced with what's defined in `UserDefaults+Woo`.
///
private extension UserDefaults {
    @objc dynamic var applicationPasswordExperimentEnabled: Bool {
        bool(forKey: "applicationPasswordExperimentEnabled")
    }
}

extension Alamofire.MultipartFormData: MultipartFormData {
    public func append(_ data: Data, withName name: String) {
        self.append(data, withName: name, fileName: nil, mimeType: nil)
    }
}

/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {
    private lazy var alamofireSession: Alamofire.Session = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = makeSession(configuration: sessionConfiguration)
        return sessionManager
    }()

    /// Converter to convert Jetpack tunnel requests into REST API requests if applicable
    ///
    private var requestConverter: RequestConverter

    /// Authenticator to update requests authorization header if possible.
    ///
    private let requestAuthenticator: RequestProcessor

    public var session: URLSession { Session.default.session }

    private var subscription: AnyCancellable?

    /// Public Initializer
    ///
    ///
    public required init(credentials: Credentials?,
                         selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                         userDefaults: UserDefaults = .standard,
                         sessionManager: Alamofire.Session? = nil) {
        self.requestConverter = {
            let siteAddress: String? = {
                switch credentials {
                case let .wporg(_, _, siteAddress):
                    return siteAddress
                case let .applicationPassword(_, _, siteAddress):
                    return siteAddress
                default:
                    return nil
                }
            }()
            return RequestConverter(siteAddress: siteAddress)
        }()
        self.requestAuthenticator = RequestProcessor(requestAuthenticator: DefaultRequestAuthenticator(credentials: credentials))
        if let sessionManager {
            self.alamofireSession = sessionManager
        }

        if let selectedSite, let credentials, case .wpcom = credentials {
            observeSelectedSite(selectedSite, credentials: credentials, userDefaults: userDefaults)
        }
    }

    /// Delete application password
    ///
    public func deleteApplicationPassword() {
        requestAuthenticator.deleteApplicationPassword()
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
        let request = requestConverter.convert(request)
        alamofireSession.request(request)
            .validateIfRestRequest(for: request)
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
        let request = requestConverter.convert(request)
        alamofireSession.request(request)
            .validateIfRestRequest(for: request)
            .responseData { response in
                if let error = response.networkingError {
                    completion(.failure(error))
                } else {
                    completion(response.result.mapError { $0 })
                }
            }
    }

    public func responseDataAndHeaders(for request: URLRequestConvertible) async throws -> (Data, ResponseHeaders?) {
        let request = requestConverter.convert(request)
        let sessionRequest = alamofireSession.request(request)
            .validateIfRestRequest(for: request)
        let response = await sessionRequest.serializingData().response
        if let error = response.networkingError {
            throw error
        }
        switch response.result {
            case .success(let data):
                return (data, response.response?.headers.dictionary)
            case .failure(let error):
                throw error
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
            let request = self.requestConverter.convert(request)
            self.alamofireSession
                .request(request)
                .validateIfRestRequest(for: request)
                .responseData { response in
                    if let error = response.networkingError {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(response.result.mapError { $0 }))
                    }
                }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        let request = requestConverter.convert(request)
        alamofireSession
            .upload(multipartFormData: multipartFormData, with: request)
            .responseData { response in
                completion(response.value, response.error)
            }
    }
}

private extension AlamofireNetwork {
    /// Creates a session manager with request retrier and adapter
    ///
    func makeSession(configuration sessionConfiguration: URLSessionConfiguration) -> Alamofire.Session {
        Alamofire.Session(configuration: sessionConfiguration, interceptor: requestAuthenticator)
    }

    /// Updates `requestConverter` and `requestAuthenticator` when selected site changes
    ///
    func observeSelectedSite(_ selectedSite: AnyPublisher<JetpackSite?, Never>,
                             credentials: Credentials,
                             userDefaults: UserDefaults) {
        subscription = selectedSite.removeDuplicates().combineLatest(
            userDefaults.publisher(for: \.applicationPasswordExperimentEnabled),
        )
        .sink { [weak self] (site, experimentEnabled) in
            guard let self else { return }
            guard let site, experimentEnabled, site.applicationPasswordAvailable else {
                requestConverter = RequestConverter(siteAddress: nil)
                requestAuthenticator.updateAuthenticator(DefaultRequestAuthenticator(credentials: credentials))
                return
            }
            requestConverter = RequestConverter(siteAddress: site.siteAddress)
            requestAuthenticator.updateAuthenticator(DefaultRequestAuthenticator(
                credentials: credentials,
                selectedSite: site,
                network: self
            ))
        }
    }
}

private extension DataRequest {
    /// Validates only for `RESTRequest`
    ///
    ///   Only `RESTRequest` needs to be checked for status codes and retried if applicable by `RequestProcessor`
    ///
    func validateIfRestRequest(for request: URLRequestConvertible) -> Self {
        guard request is RESTRequest else {
            return self
        }
        return validate()
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
            NetworkError(responseData: data,
                         statusCode: response.statusCode)
        }
    }
}
