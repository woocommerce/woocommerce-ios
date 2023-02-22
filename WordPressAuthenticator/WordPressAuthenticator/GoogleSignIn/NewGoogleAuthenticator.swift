import AuthenticationServices

public class NewGoogleAuthenticator: NSObject {

    let clientId: GoogleClientId
    let scheme: String
    let audience: String
    let contextProvider: ASWebAuthenticationPresentationContextProviding

    let oauthTokenGetter: GoogleOAuthTokenGetting

    public convenience init(
        clientId: GoogleClientId,
        scheme: String,
        audience: String,
        contextProvider: ASWebAuthenticationPresentationContextProviding,
        urlSession: URLSession
    ) {
        self.init(
            clientId: clientId,
            scheme: scheme,
            audience: audience,
            contextProvider: contextProvider,
            oautTokenGetter: GoogleOAuthTokenGetter(dataGetter: urlSession)
        )
    }

    init(
        clientId: GoogleClientId,
        scheme: String,
        audience: String,
        contextProvider: ASWebAuthenticationPresentationContextProviding,
        oautTokenGetter: GoogleOAuthTokenGetting
    ) {
        self.clientId = clientId
        self.scheme = scheme
        self.audience = audience
        self.oauthTokenGetter = oautTokenGetter
        self.contextProvider = contextProvider
    }

    /// Get the user's OAuth token from their Google account. This token can be used to authenticate with the WordPress backend.
    public func getOAuthToken() async throws -> IDToken {
        let pkce = try ProofKeyForCodeExchange()
        let url = try await getURL(clientId: clientId, scheme: scheme, pkce: pkce)
        return try await requestOAuthToken(url: url, clientId: clientId, audience: audience, pkce: pkce)
    }

    func getURL(clientId: GoogleClientId, scheme: String, pkce: ProofKeyForCodeExchange) async throws -> URL {
        let url = try URL.googleSignInAuthURL(clientId: clientId, pkce: pkce)
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: { result in
                    continuation.resume(with: result)
                }
            )

            session.presentationContextProvider = contextProvider
            // At this point in time, we don't see the need to make the session ephemeral.
            //
            // Additionally, from a user's perspective, it would be frustrating to have to
            // authenticate with Google again unless necessary—it certainly would be when testing
            // the app.
            session.prefersEphemeralWebBrowserSession = false

            // FIXME: Need this to avoid TSAN error in demo app. Can we move the call elsewhere?
            DispatchQueue.main.async {
                session.start()
            }
        }
    }

    func requestOAuthToken(
        url: URL,
        clientId: GoogleClientId,
        audience: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> IDToken {
        guard let authCode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value else {
            throw OAuthError.urlDidNotContainCodeParameter(url: url)
        }

        let response = try await oauthTokenGetter.getToken(
            clientId: clientId,
            audience: audience,
            authCode: authCode,
            pkce: pkce
        )

        guard let idToken = response.idToken else {
            throw OAuthError.tokenResponseDidNotIncludeIdToken
        }

        return idToken
    }
}
