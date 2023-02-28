enum OAuthError: LocalizedError {

    // ASWebAuthenticationSession
    case inconsistentWebAuthenticationSessionCompletion

    case failedToGenerateSecureRandomCodeVerifier(status: Int32)

    var errorDescription: String {
        switch self {
        case .inconsistentWebAuthenticationSessionCompletion:
            return "ASWebAuthenticationSession authentication finished with neither a callback URL nor error"
        case .failedToGenerateSecureRandomCodeVerifier(let status):
            return "Could not generate a cryptographically secure random PKCE code verifier value. Underlying error code \(status)"
       }
    }
}
