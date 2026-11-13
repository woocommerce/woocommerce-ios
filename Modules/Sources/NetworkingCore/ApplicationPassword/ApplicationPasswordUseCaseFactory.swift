import Foundation

/// Creates application-password use cases with the authentication context required by WordPress.org sites.
public struct ApplicationPasswordUseCaseFactory {
    public typealias MakeWordPressOrgUseCase = (
        _ username: String,
        _ password: String,
        _ siteAddress: String,
        _ authenticationEndpoints: CookieNonceAuthenticationEndpoints?,
        _ detectUnexpectedResponses: Bool
    ) throws -> ApplicationPasswordUseCase

    private let makeWordPressOrgUseCase: MakeWordPressOrgUseCase

    public init(makeWordPressOrgUseCase: @escaping MakeWordPressOrgUseCase = {
        try DefaultApplicationPasswordUseCase(
            username: $0,
            password: $1,
            siteAddress: $2,
            authenticationEndpoints: $3,
            detectUnexpectedResponses: $4
        )
    }) {
        self.makeWordPressOrgUseCase = makeWordPressOrgUseCase
    }

    public func makeForWordPressOrg(username: String,
                                    password: String,
                                    siteAddress: String,
                                    authenticationEndpoints: CookieNonceAuthenticationEndpoints?,
                                    detectUnexpectedResponses: Bool = false) throws -> ApplicationPasswordUseCase {
        try makeWordPressOrgUseCase(username, password, siteAddress, authenticationEndpoints, detectUnexpectedResponses)
    }
}
