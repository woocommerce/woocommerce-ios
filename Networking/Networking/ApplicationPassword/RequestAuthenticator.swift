enum RequestAuthenticatorError: Error {
    case applicationPasswordUseCaseNotAvailable
    case applicationPasswordNotAvailable
}

protocol RequestAuthenticator {
    /// Credentials to authenticate the URLRequest
    ///
    var credentials: Credentials? { get }

    /// Authenticates the provided urlRequest using the `credentials`
    ///
    /// - Parameter urlRequest: `URLRequest` to authenticate
    /// - Returns: Authenticated `URLRequest`
    ///
    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest

    /// Generates application password
    ///
    func generateApplicationPassword() async throws

    /// Checks whether the given URLRequest is eligible for retyring
    ///
    func shouldRetry(_ urlRequest: URLRequest) -> Bool
}

/// Authenticates request
///
public struct DefaultRequestAuthenticator: RequestAuthenticator {
    /// Credentials to authenticate the URLRequest
    ///
    let credentials: Credentials?

    /// The use case to handle authentication with application passwords.
    ///
    private let applicationPasswordUseCase: ApplicationPasswordUseCase?

    /// Sets up the authenticator with optional credentials and application password use case.
    /// `applicationPasswordUseCase` can be injected for unit tests.
    ///
    init(credentials: Credentials?, applicationPasswordUseCase: ApplicationPasswordUseCase? = nil) {
        self.credentials = credentials
        let useCase: ApplicationPasswordUseCase? = {
            if let applicationPasswordUseCase {
                return applicationPasswordUseCase
            } else {
                switch credentials {
                case let .wporg(username, password, siteAddress):
                    return try? DefaultApplicationPasswordUseCase(username: username, password: password, siteAddress: siteAddress)
                case let .applicationPassword(_, _, siteAddress):
                    return OneTimeApplicationPasswordUseCase(siteAddress: siteAddress)
                case .wpcom:
                    if let passwordCompanion = credentials?.appPasswordCompanion {
                        return OneTimeApplicationPasswordUseCase(siteAddress: passwordCompanion.siteURL)
                    }
                    fallthrough
                default:
                    return nil
                }
            }
        }()
        self.applicationPasswordUseCase = useCase
    }

    /// Authenticates the provided urlRequest using the `credentials`
    ///
    /// - Parameter urlRequest: `URLRequest` to authenticate
    /// - Returns: Authenticated `URLRequest`
    ///
    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        if isRestAPIRequest(urlRequest) {
            return try authenticateUsingApplicationPasswordIfPossible(urlRequest)
        } else {
            return try authenticateUsingWPCOMTokenIfPossible(urlRequest)
        }
    }

    /// Generates application password
    ///
    func generateApplicationPassword() async throws {
        guard let applicationPasswordUseCase else {
            throw RequestAuthenticatorError.applicationPasswordUseCaseNotAvailable
        }
        let _ = try await applicationPasswordUseCase.generateNewPassword()
        return
    }

    /// Checks whether the given URLRequest is eligible for retyring
    ///
    func shouldRetry(_ urlRequest: URLRequest) -> Bool {
        isRestAPIRequest(urlRequest)
    }
}

private extension DefaultRequestAuthenticator {
    /// To check whether the given URLRequest is a REST API request
    ///
    func isRestAPIRequest(_ urlRequest: URLRequest) -> Bool {
        let siteAddress: String? = {
            switch credentials {
            case let .wporg(_, _, siteAddress):
                return siteAddress
            case let .applicationPassword(_, _, siteAddress):
                return siteAddress
            case .wpcom:
                guard let siteURL = credentials?.appPasswordCompanion?.siteURL,
                      let host = urlRequest.url?.host(),
                      siteURL.contains(host) else {
                    return nil
                }
                return siteURL // Add docs
            default:
                return nil
            }
        }()
        guard let siteAddress,
              let url = urlRequest.url,
              url.absoluteString.hasPrefix(siteAddress.trimSlashes() + "/" + RESTRequest.Settings.basePath) else {
            return false
        }
        return true
    }

    /// Attempts creating a request with WPCOM token if possible.
    ///
    func authenticateUsingWPCOMTokenIfPossible(_ urlRequest: URLRequest) throws -> URLRequest {
        guard case let .wpcom(_, authToken, _) = credentials else {
            return UnauthenticatedRequest(request: urlRequest).asURLRequest()
        }

        return AuthenticatedDotcomRequest(authToken: authToken, request: urlRequest).asURLRequest()
    }

    /// Attempts creating a request with application password if possible.
    ///
    func authenticateUsingApplicationPasswordIfPossible(_ urlRequest: URLRequest) throws -> URLRequest {

        // TODO: check error here
        guard let applicationPassword = applicationPasswordUseCase?.applicationPassword else {
            throw RequestAuthenticatorError.applicationPasswordNotAvailable
        }

        return AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: urlRequest).asURLRequest()
    }
}
