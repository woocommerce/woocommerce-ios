enum RequestAuthenticatorError: Error {
    case applicationPasswordUseCaseNotAvailable
    case applicationPasswordNotAvailable
}

/// Authenticates request
///
public struct RequestAuthenticator {
    /// Credentials.
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
            } else if case let .wporg(username, password, siteAddress) = credentials {
                return try? DefaultApplicationPasswordUseCase(username: username,
                                                              password: password,
                                                              siteAddress: siteAddress)
            } else {
                return nil
            }
        }()
        self.applicationPasswordUseCase = useCase
    }

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        guard isRestAPIRequest(urlRequest) else {
            // Handle non-REST requests as before
            return try authenticateUsingWPCOMTokenIfPossible(urlRequest)
        }

        return try authenticateUsingApplicationPasswordIfPossible(urlRequest)
    }

    func generateApplicationPassword() async throws {
        guard let applicationPasswordUseCase = applicationPasswordUseCase else {
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

private extension RequestAuthenticator {
    /// To check whether the given URLRequest is a REST API request
    ///
    /// - Parameter urlRequest: urlRequest to check
    /// - Returns: `true` is the urlRequest is a REST API request
    ///
    func isRestAPIRequest(_ urlRequest: URLRequest) -> Bool {
        guard case let .wporg(_, _, siteAddress) = credentials,
              let url = urlRequest.url,
              url.absoluteString.hasPrefix(siteAddress.trimSlashes() + "/" + RESTRequest.Settings.basePath) else {
            return false
        }
        return true
    }

    /// Attempts creating a request with WPCOM token if possible.
    ///
    func authenticateUsingWPCOMTokenIfPossible(_ urlRequest: URLRequest) throws -> URLRequest {
        if let credentials, case .wpcom = credentials {
            return try AuthenticatedRequest(credentials: credentials, request: urlRequest).asURLRequest()
        }
        return UnauthenticatedRequest(request: urlRequest).asURLRequest()
    }

    /// Attempts creating a request with application password if possible.
    ///
    func authenticateUsingApplicationPasswordIfPossible(_ urlRequest: URLRequest) throws -> URLRequest {
        guard let applicationPassword = applicationPasswordUseCase?.applicationPassword else {
            throw RequestAuthenticatorError.applicationPasswordNotAvailable
        }

        var request = urlRequest
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let username = applicationPassword.wpOrgUsername
        let password = applicationPassword.password.secretValue
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            return request
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        // Cookies from `CookieNonceAuthenticator` should be skipped
        request.httpShouldHandleCookies = false

        return request
    }
}
