protocol GoogleOAuthTokenGetting {

    func getToken(
        clientId: GoogleClientId,
        authCode: String,
        pkce: ProofKeyForCodeExchange
    ) async throws -> OAuthTokenResponseBody
}
