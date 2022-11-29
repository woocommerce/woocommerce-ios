enum OAuthErrors {

    static let inconsistentASWebAuthenticationSessionCompletion = NSError(
        domain: "org.wordpress.authenticator.oauth",
        code: 1,
        userInfo: [
            NSLocalizedDescriptionKey: "ASWebAuthenticationSession authentication finished with neither a callback URL nor error"
        ]
    )
}
