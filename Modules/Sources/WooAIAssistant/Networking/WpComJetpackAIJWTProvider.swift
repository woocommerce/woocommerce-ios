import Foundation

// Concurrent `currentJWT()` callers share one in-flight mint via a stored Task.
// Plain actor isolation isn't enough: `await mint(...)` suspends, the actor lets the
// next caller re-enter, that caller sees the still-unset cache and starts a second
// mint. Holding a Task<String, Error> while the first call is in flight makes
// followers await the same value.
public actor WpComJetpackAIJWTProvider: AssistantJWTProviding {

    public typealias Mint = @Sendable (Int64) async throws -> String

    private let blogID: Int64
    private let mint: Mint
    private var cached: CachedJWT?
    private var inflight: Task<String, Error>?

    public init(blogID: Int64, mint: @escaping Mint) {
        self.blogID = blogID
        self.mint = mint
    }

    public func currentJWT() async throws -> String {
        if let cached, cached.matchesBlog(blogID), !cached.isExpired {
            return cached.token
        }
        if let inflight {
            return try await inflight.value
        }
        let blogID = self.blogID
        let mint = self.mint
        let task = Task<String, Error> { try await mint(blogID) }
        inflight = task
        defer { inflight = nil }
        let fresh = try await task.value
        cached = try CachedJWT(token: fresh)
        return fresh
    }

    public func invalidate() async {
        cached = nil
    }
}

struct CachedJWT: Equatable, Sendable {
    let token: String
    let blogID: Int64
    let expiresAt: Date

    init(token: String) throws {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            throw AssistantError(kind: .auth, message: "Jetpack AI JWT does not have three segments.")
        }
        let payloadSegment = String(segments[1])
        guard let payloadData = Self.base64URLDecode(payloadSegment) else {
            throw AssistantError(kind: .auth, message: "Jetpack AI JWT payload is not valid base64url.")
        }
        let decoded: Payload
        do {
            decoded = try JSONDecoder().decode(Payload.self, from: payloadData)
        } catch {
            throw AssistantError(kind: .auth, message: "Jetpack AI JWT payload is not valid JSON: \(error).")
        }
        guard let blogID = decoded.blogID else {
            throw AssistantError(kind: .auth, message: "Jetpack AI JWT payload is missing blog_id.")
        }
        guard let exp = decoded.exp else {
            throw AssistantError(kind: .auth, message: "Jetpack AI JWT payload is missing exp.")
        }
        self.token = token
        self.blogID = blogID
        self.expiresAt = Date(timeIntervalSince1970: TimeInterval(exp))
    }

    func matchesBlog(_ id: Int64) -> Bool {
        blogID == id
    }

    // Expire 60s early so a token whose true `exp` is just past `now` doesn't get
    // shipped on a request that the proxy will then reject. Mirrors typical
    // clock-skew margin and avoids 401-then-retry cycles at the boundary.
    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }

    // JWT payload is base64url (`-_` instead of `+/`) with padding elided.
    private static func base64URLDecode(_ input: String) -> Data? {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }

    private struct Payload: Decodable {
        let blogID: Int64?
        let exp: Int64?

        enum CodingKeys: String, CodingKey {
            case blogID = "blog_id"
            case exp
        }
    }
}
