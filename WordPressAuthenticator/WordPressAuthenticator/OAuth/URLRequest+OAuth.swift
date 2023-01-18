extension URLRequest {

    static func oauthTokenRequest(baseURL: URL) throws -> URLRequest {
        var request = try URLRequest(url: baseURL, method: .post)
        request.setValue(
            "application/x-www-form-urlencoded; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        return request
    }
}
