extension URLRequest {

    static func googleSignInTokenRequest(
        body: OAuthTokenRequestBody
    ) throws -> URLRequest {
        var request = try URLRequest(url: URL.googleSignInOAuthTokenURL, method: .post)

        request.setValue(
            "application/x-www-form-urlencoded; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try body.asURLEncodedData()

        return request
    }
}
