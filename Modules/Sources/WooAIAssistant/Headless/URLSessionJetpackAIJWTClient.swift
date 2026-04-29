import Foundation
import CocoaLumberjackSwift

/// `AssistantJWTProviding` that mints AI JWTs against the merchant's own
/// `<siteURL>/wp-json/jetpack/v4/jetpack-ai-jwt` endpoint with HTTP Basic
/// auth. The harness lives outside the Jetpack tunnel, so the merchant's
/// app password is the only viable credential.
///
/// Mints are de-duped through a process-wide actor cache keyed on
/// `(siteURL, basicAuthHeader)`. Concurrent smoke runs against the same
/// merchant share one in-flight Task and reuse the resolved token, which
/// avoids the wpcom rate limiter every parallel run hit when each test
/// case minted in isolation.
public struct URLSessionJetpackAIJWTClient: AssistantJWTProviding {

    public typealias Mint = @Sendable (URL, String, URLSession) async throws -> String

    private let siteURL: URL
    private let basicAuthHeader: String
    private let session: URLSession
    private let cacheKey: String
    private let mint: Mint

    public init(siteURL: URL,
                username: String,
                appPassword: String,
                session: URLSession = .shared) {
        self.init(siteURL: siteURL,
                  username: username,
                  appPassword: appPassword,
                  session: session,
                  mint: Self.defaultMint)
    }

    // Internal seam: tests inject a stub mint to exercise the cache without going to the network.
    init(siteURL: URL,
         username: String,
         appPassword: String,
         session: URLSession = .shared,
         mint: @escaping Mint) {
        self.siteURL = siteURL
        self.session = session
        // Strip whitespace from the app password before encoding. The Jetpack mint endpoint
        // rejects spaced "abcd efgh" passwords with a 401 even though wp-admin accepts them.
        let strippedPassword = appPassword.replacingOccurrences(of: " ", with: "")
        let raw = "\(username):\(strippedPassword)"
        let encoded = Data(raw.utf8).base64EncodedString()
        self.basicAuthHeader = "Basic \(encoded)"
        self.cacheKey = "\(siteURL.absoluteString)|\(encoded)"
        self.mint = mint
    }

    public func currentJWT() async throws -> String {
        let cacheKey = self.cacheKey
        let siteURL = self.siteURL
        let header = self.basicAuthHeader
        let session = self.session
        let mint = self.mint
        return try await Self.cache.tokenForMinting(key: cacheKey) {
            try await mint(siteURL, header, session)
        }
    }

    public func invalidate() async {
        await Self.cache.invalidate(key: cacheKey)
    }

    static let defaultMint: Mint = { siteURL, basicAuthHeader, session in
        let endpoint = siteURL.appendingPathComponent("wp-json/jetpack/v4/jetpack-ai-jwt")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AssistantError(kind: .network, message: "Headless JWT mint received a non-HTTP response.")
        }
        if !(200..<300).contains(http.statusCode) {
            let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
            throw AssistantError(kind: .auth,
                                 code: String(http.statusCode),
                                 message: "Headless JWT mint failed (HTTP \(http.statusCode)): \(snippet)")
        }
        struct Envelope: Decodable {
            let token: String?
            let jwt: String?
        }
        do {
            let decoded = try JSONDecoder().decode(Envelope.self, from: data)
            if let token = decoded.token, !token.isEmpty { return token }
            if let jwt = decoded.jwt, !jwt.isEmpty { return jwt }
        } catch {
            DDLogError("URLSessionJetpackAIJWTClient mint envelope decode failed: \(error)")
        }
        let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
        throw AssistantError(kind: .auth,
                             message: "Headless JWT mint expected `token` in response body, got: \(snippet)")
    }

    static let cache = JWTCache()
}

actor JWTCache {

    private var cached: [String: String] = [:]
    private var inflight: [String: Task<String, Error>] = [:]

    func tokenForMinting(key: String,
                         mint: @Sendable @escaping () async throws -> String) async throws -> String {
        if let existing = cached[key] {
            return existing
        }
        if let inflightTask = inflight[key] {
            return try await inflightTask.value
        }
        let task = Task<String, Error> {
            try await mint()
        }
        inflight[key] = task
        defer { inflight[key] = nil }
        let token = try await task.value
        cached[key] = token
        return token
    }

    func invalidate(key: String) {
        cached[key] = nil
    }

    func reset() {
        cached.removeAll()
        inflight.removeAll()
    }

    func cachedTokenCount() -> Int {
        cached.count
    }
}
