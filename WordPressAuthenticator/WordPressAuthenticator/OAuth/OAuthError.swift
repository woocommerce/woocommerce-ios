enum OAuthError: LocalizedError {

    // ASWebAuthenticationSession
    case inconsistentWebAuthenticationSessionCompletion

    // OAuth token request
    case failedToBuildURLQuery
    case failedToEncodeURLQuery(query: String)

    var errorDescription: String {
        switch self {
        case .inconsistentWebAuthenticationSessionCompletion:
            return "ASWebAuthenticationSession authentication finished with neither a callback URL nor error"
        case .failedToBuildURLQuery:
            return "Failed to build URL query string"
        case .failedToEncodeURLQuery(let query):
            return "Failed to encode URL query string '\(query)'"
        }
    }
}
