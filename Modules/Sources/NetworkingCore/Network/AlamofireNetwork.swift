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

public enum RequestAuthenticationMode: String {
    case appPasswords = "app_passwords"
    case appPasswordsWithJetpack = "app_passwords_with_jetpack" // switching to app password for Jetpack sites
    case jetpackTunnel = "jetpack_tunnel"
}

extension Alamofire.MultipartFormData: MultipartFormData {
    public func append(_ data: Data, withName name: String) {
        self.append(data, withName: name, fileName: nil, mimeType: nil)
    }
}

/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {

    /// authentication mode for requests
    public private(set) var authenticationMode: RequestAuthenticationMode?

    /// Session manager used for Alamofire requests.
    private let alamofireSession: Alamofire.Session

    private let credentials: Credentials?

    private let selectedSite: AnyPublisher<JetpackSite?, Never>?

    private let userDefaults: UserDefaults

    /// Converter to convert Jetpack tunnel requests into REST API requests if applicable
    ///
    private var requestConverter: RequestConverter

    /// Authenticator to update requests authorization header if possible.
    ///
    private let requestAuthenticator: RequestProcessor

    public var session: URLSession { Session.default.session }

    private var siteSubscription: AnyCancellable?

    /// Thread-safe error handler for failure tracking and retry logic
    private let errorHandler: AlamofireNetworkErrorHandler

    private var appPasswordSupportSubscription: AnyCancellable?

    /// Public Initializer
    ///
    /// - Parameters:
    ///   - credentials: Authentication credentials for requests.
    ///   - selectedSite: Publisher for site selection changes.
    ///   This is necessary if you wish to enable network switching to direct requests while authenticated with WPCOM for better performance.
    ///   - sessionManager: Optional pre-configured session manager.
    public required init(credentials: Credentials?,
                         selectedSite: AnyPublisher<JetpackSite?, Never>?,
                         appPasswordSupportState: AnyPublisher<Bool, Never>?,
                         userDefaults: UserDefaults = .standard,
                         sessionManager: Alamofire.Session? = nil) {
        self.credentials = credentials
        self.selectedSite = selectedSite
        self.userDefaults = userDefaults
        self.errorHandler = AlamofireNetworkErrorHandler(credentials: credentials, userDefaults: userDefaults)
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
        let requestAuthenticator = RequestProcessor(requestAuthenticator: DefaultRequestAuthenticator(credentials: credentials))
        self.requestAuthenticator = requestAuthenticator
        if let sessionManager {
            self.alamofireSession = sessionManager
        } else {
            // The uploadStreamProvider event monitor tracks which upload data
            // belongs to each URLSessionTask so the delegate can provide it
            // when needNewBodyStream is called.
            let delegate = SafeUploadSessionDelegate()
            self.alamofireSession = Alamofire.Session(
                configuration: .default,
                delegate: delegate,
                interceptor: requestAuthenticator,
                eventMonitors: [delegate.uploadStreamProvider]
            )
        }

        let authenticationMode: RequestAuthenticationMode? = {
            switch credentials {
            case .wporg, .applicationPassword:
                return .appPasswords
            case .wpcom:
                return .jetpackTunnel
            case .none:
                return nil
            }
        }()
        updateAuthenticationMode(authenticationMode)
        if let appPasswordSupportState {
            observeAppPasswordSupportState(appPasswordSupportState)
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
    /// - Note:
    ///     - The response body will always be returned (when possible), even when there's a networking error.
    ///       This differs slightly from the standard Alamofire `.validate()` behavior, and it's required so that
    ///       the upper layers can properly detect "Jetpack Tunnel" Errors.
    ///     - Yes. We do the above because the Jetpack Tunnel endpoint doesn't properly relay the correct statusCode.
    ///
    public func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        let convertedRequest = convertRequestIfNeeded(request)
        alamofireSession.request(convertedRequest)
            .validateIfRestRequest(for: convertedRequest)
            .responseData { [weak self] response in
                self?.errorHandler.handleFailureForDirectRequestIfNeeded(
                    originalRequest: request,
                    convertedRequest: convertedRequest,
                    failure: response.networkingError,
                    onRetry: {
                        self?.responseData(for: request, completion: completion)
                    },
                    onCompletion: {
                        completion(response.value, response.networkingError)
                    }
                )
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
        let convertedRequest = convertRequestIfNeeded(request)
        alamofireSession.request(convertedRequest)
            .validateIfRestRequest(for: convertedRequest)
            .responseData { [weak self] response in
                self?.errorHandler.handleFailureForDirectRequestIfNeeded(
                    originalRequest: request,
                    convertedRequest: convertedRequest,
                    failure: response.networkingError,
                    onRetry: {
                        self?.responseData(for: request, completion: completion)
                    },
                    onCompletion: {
                        if let error = response.networkingError {
                            completion(.failure(error))
                        } else {
                            completion(response.result.mapError { $0 })
                        }
                    }
                )
            }
    }

    public func responseDataAndHeaders(for request: URLRequestConvertible) async throws -> (Data, ResponseHeaders?) {
        let convertedRequest = convertRequestIfNeeded(request)
        let sessionRequest = alamofireSession.request(convertedRequest)
            .validateIfRestRequest(for: convertedRequest)
        let response = await sessionRequest.serializingData().response
        let failure = response.networkingError

        if errorHandler.shouldRetryJetpackRequest(
            originalRequest: request,
            convertedRequest: convertedRequest,
            failure: failure
        ) {
            return try await responseDataAndHeaders(for: request)
        }

        errorHandler.flagSiteAsUnsupportedForAppPasswordIfNeeded(originalRequest: request, failure: failure)

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
            let convertedRequest = self.convertRequestIfNeeded(request)
            self.alamofireSession
                .request(convertedRequest)
                .validateIfRestRequest(for: convertedRequest)
                .responseData { [weak self] response in
                    self?.errorHandler.handleFailureForDirectRequestIfNeeded(
                        originalRequest: request,
                        convertedRequest: convertedRequest,
                        failure: response.networkingError,
                        onRetry: {
                            self?.responseData(for: request) { result in
                                promise(.success(result))
                            }
                        },
                        onCompletion: {
                            if let error = response.networkingError {
                                promise(.success(.failure(error)))
                            } else {
                                promise(.success(response.result.mapError { $0 }))
                            }
                        }
                    )
                }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                        to request: URLRequestConvertible,
                                        completion: @escaping (Data?, Error?) -> Void) {
        let convertedRequest = self.convertRequestIfNeeded(request)
        alamofireSession
            .upload(multipartFormData: multipartFormData, with: convertedRequest)
            .responseData { [weak self] response in
                self?.errorHandler.handleFailureForDirectRequestIfNeeded(
                    originalRequest: request,
                    convertedRequest: convertedRequest,
                    failure: response.networkingError,
                    onRetry: {
                        self?.uploadMultipartFormData(multipartFormData: multipartFormData, to: request, completion: completion)
                    },
                    onCompletion: {
                        completion(response.value, response.error)
                    }
                )
            }
    }
}

private extension AlamofireNetwork {

    func observeAppPasswordSupportState(_ appPasswordSupportState: AnyPublisher<Bool, Never>) {
        appPasswordSupportSubscription = appPasswordSupportState
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.updateAppPasswordSwitching(enabled: enabled)
            }
    }

    func updateAppPasswordSwitching(enabled: Bool) {
        guard let credentials, case .wpcom = credentials else { return }
        if enabled, let selectedSite {
            observeSelectedSite(selectedSite)
        } else {
            requestConverter = RequestConverter(siteAddress: nil)
            requestAuthenticator.updateAuthenticator(DefaultRequestAuthenticator(credentials: credentials))
            requestAuthenticator.delegate = nil
            updateAuthenticationMode(.jetpackTunnel)
            siteSubscription = nil
        }
    }

    /// Updates `requestConverter` and `requestAuthenticator` when selected site changes
    ///
    func observeSelectedSite(_ selectedSite: AnyPublisher<JetpackSite?, Never>) {
        siteSubscription = selectedSite
            .removeDuplicates()
            .combineLatest(userDefaults.publisher(for: \.applicationPasswordUnsupportedList))
            .sink { [weak self] site, unsupportedList in
                guard let self else { return }
                guard let site, site.applicationPasswordAvailable,
                      errorHandler.siteFlaggedAsUnsupported(
                        siteID: site.siteID,
                        unsupportedList: unsupportedList
                      ) == false else {
                    requestConverter = RequestConverter(siteAddress: nil)
                    requestAuthenticator.updateAuthenticator(DefaultRequestAuthenticator(credentials: credentials))
                    requestAuthenticator.delegate = nil
                    updateAuthenticationMode(.jetpackTunnel)
                    return
                }
                requestConverter = RequestConverter(siteAddress: site.siteAddress)
                requestAuthenticator.updateAuthenticator(DefaultRequestAuthenticator(
                    credentials: credentials,
                    selectedSite: site,
                    network: self
                ))
                requestAuthenticator.delegate = self
                errorHandler.prepareAppPasswordSupport(for: site.siteID) // reset failure count
                updateAuthenticationMode(.appPasswordsWithJetpack)
            }
    }

    func updateAuthenticationMode(_ mode: RequestAuthenticationMode?) {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationMode = mode
        }
    }
}

// MARK: Helper methods for error handling
//
private extension AlamofireNetwork {
    func convertRequestIfNeeded(_ request: URLRequestConvertible) -> URLRequestConvertible {
        if errorHandler.isRequestRetried(request) {
            return request // do not convert
        }
        return requestConverter.convert(request)
    }

}

// MARK: `RequestProcessorDelegate` conformance
//
extension AlamofireNetwork: RequestProcessorDelegate {
    func didFailToAuthenticateRequestWithAppPassword(siteID: Int64, error: Error) {
        errorHandler.flagSiteAsUnsupported(
            for: siteID,
            flow: .appPasswordGeneration,
            cause: .majorError,
            error: error
        )
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

        if case .some(AFError.requestRetryFailed) = error?.asAFError {
            return error?.asAFError
        }

        return response.flatMap { response in
            NetworkError(responseData: data,
                         statusCode: response.statusCode)
        }
    }
}

// MARK: - Helper extension to save internal flag for app password availability
//
extension UserDefaults {
    @objc dynamic var applicationPasswordUnsupportedList: [String: Date] {
        get { value(forKey: Key.applicationPasswordUnsupportedList.rawValue) as? [String: Date] ?? [:] }
        set { setValue(newValue, forKey: Key.applicationPasswordUnsupportedList.rawValue) }
    }

    enum Key: String {
        case applicationPasswordUnsupportedList
    }
}
