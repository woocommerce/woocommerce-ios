import Foundation

/// Caches a Jetpack AI JWT in process and refreshes it on expiry / blog mismatch.
///
/// Single-flight is automatic via actor isolation: only one task runs inside the actor
/// at a time, so concurrent callers serialize on `currentJWT()` and the second caller
/// observes the freshly-minted token in the cache instead of triggering a second mint.
public actor WpComJetpackAIJWTProvider: AssistantJWTProviding {

    public typealias Mint = @Sendable (Int64) async throws -> String

    private let blogID: Int64
    private let mint: Mint
    private var cached: CachedJWT?

    public init(blogID: Int64, mint: @escaping Mint) {
        self.blogID = blogID
        self.mint = mint
    }

    public func currentJWT() async throws -> String {
        if let cached, cached.matchesBlog(blogID), !cached.isExpired {
            return cached.token
        }
        let fresh = try await mint(blogID)
        let parsed = try CachedJWT(token: fresh)
        cached = parsed
        return fresh
    }

    public func invalidate() async {
        cached = nil
    }
}

/// Decoded view of a Jetpack AI JWT. The provider only needs `blog_id` and `exp`
/// from the payload to decide whether to reuse or refresh; signature is verified
/// upstream by the proxy on each request, not here.
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

    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// JWT payload uses base64url (`-_` instead of `+/`) and elides padding.
    /// Convert to standard base64 and pad before handing to `Data(base64Encoded:)`.
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
