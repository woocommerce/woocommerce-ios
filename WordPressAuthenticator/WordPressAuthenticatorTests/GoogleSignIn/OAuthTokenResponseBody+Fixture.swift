@testable import WordPressAuthenticator

extension OAuthTokenResponseBody {

    static func fixture(idToken: String? = "id_token") -> Self {
        OAuthTokenResponseBody(
            accessToken: "access_token",
            expiresIn: 1,
            idToken: idToken,
            refreshToken: .none,
            scope: "s",
            tokenType: "t"
        )
    }
}
