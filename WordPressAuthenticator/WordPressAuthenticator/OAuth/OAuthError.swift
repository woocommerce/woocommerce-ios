enum OAuthError: LocalizedError {

    // ASWebAuthenticationSession
    case inconsistentWebAuthenticationSessionCompletion

    var errorDescription: String {
        switch self {
        case .inconsistentWebAuthenticationSessionCompletion:
            return "ASWebAuthenticationSession authentication finished with neither a callback URL nor error"
        }
    }
}
