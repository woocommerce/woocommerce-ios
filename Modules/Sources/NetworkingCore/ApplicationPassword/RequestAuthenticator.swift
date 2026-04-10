import Foundation

public enum RequestAuthenticatorError: Error {
    case applicationPasswordUseCaseNotAvailable
    case applicationPasswordNotAvailable
}

protocol RequestAuthenticator {
    /// Credentials to authenticate the URLRequest
    ///
    var credentials: Credentials? { get }

    var jetpackSiteID: Int64? { get }

    /// Authenticates the provided urlRequest using the `credentials`
    ///
    /// - Parameter urlRequest: `URLRequest` to authenticate
    /// - Returns: Authenticated `URLRequest`
    ///
    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest

    /// Generates application password
    ///
    func generateApplicationPassword() async throws

    /// Delete existing application password remotely
    ///
    func deleteApplicationPassword() async throws

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

    /// ID of current site if Jetpack site
    ///
    let jetpackSiteID: Int64?

    /// The use case to handle authentication with application passwords.
    ///
    private let applicationPasswordUseCase: ApplicationPasswordUseCase?

    private let siteAddress: String?

    /// Sets up the authenticator with optional credentials and application password use case.
    /// `applicationPasswordUseCase` can be injected for unit tests.
    ///
    init(credentials: Credentials?,
         selectedSite: JetpackSite? = nil,
         applicationPasswordUseCase: ApplicationPasswordUseCase? = nil,
         network: Network? = nil) {
        self.credentials = credentials

        self.applicationPasswordUseCase  = {
            if let applicationPasswordUseCase {
                return applicationPasswordUseCase
            }
            switch credentials {
            case let .some(.wporg(username, password, siteAddress)):
                return try? DefaultApplicationPasswordUseCase(username: username,
                                                              password: password,
                                                              siteAddress: siteAddress)
            case .some(.applicationPassword(_, _, let siteAddress)):
                return OneTimeApplicationPasswordUseCase(siteAddress: siteAddress)
            case .some(.wpcom):
                guard let network, let selectedSite else {
                    return nil
                }
                return DefaultApplicationPasswordUseCase(
                    type: .wpcom(siteID: selectedSite.siteID),
                    network: network
                )
            default:
                return nil
            }
        }()

        self.siteAddress = {
            switch credentials {
            case let .some(.wporg(_, _, siteAddress)):
                return siteAddress
            case let .some(.applicationPassword(_, _, siteAddress)):
                return siteAddress
            default:
                return selectedSite?.siteAddress
            }
        }()

        jetpackSiteID = selectedSite?.siteID
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

    func deleteApplicationPassword() async throws {
        guard let applicationPasswordUseCase else {
            throw RequestAuthenticatorError.applicationPasswordUseCaseNotAvailable
        }
        try await applicationPasswordUseCase.deletePassword(locally: false)
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
        guard let siteAddress, let url = urlRequest.url else { return false }
        let absoluteString = url.absoluteString
        let siteBase = siteAddress.trimSlashes()

        // Use cached REST API root if available, otherwise fall back to default
        let restRoot = WordPressRESTAPIRootCache.shared.root(for: siteAddress)
            ?? (siteBase + "/" + RESTRequest.Settings.basePath)
        return absoluteString.hasPrefix(restRoot.trimSlashes())
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
        guard let applicationPassword = applicationPasswordUseCase?.applicationPassword else {
            throw RequestAuthenticatorError.applicationPasswordNotAvailable
        }

        return AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: urlRequest).asURLRequest()
    }
}
