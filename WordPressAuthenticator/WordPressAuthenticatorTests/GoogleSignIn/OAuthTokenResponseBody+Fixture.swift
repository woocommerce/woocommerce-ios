@testable import WordPressAuthenticator

extension OAuthTokenResponseBody {

    static func fixture(accessToken: String = "access_token") -> Self {
        OAuthTokenResponseBody(
            accessToken: accessToken,
            expiresIn: 1,
            idToken: .none,
            refreshToken: .none,
            scope: "s",
            tokenType: "t"
        )
    }
}
