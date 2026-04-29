import Foundation
import CocoaLumberjackSwift

// Single-flight via a stored in-flight Task. Actor isolation alone isn't enough:
// `await mint(...)` suspends, lets a second caller see the unset cache, and double-mints.
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
            DDLogError("⛔️ Jetpack AI JWT does not have three segments")
            throw AssistantError(kind: .auth, message: Localization.invalidJWT)
        }
        let payloadSegment = String(segments[1])
        guard let payloadData = Self.base64URLDecode(payloadSegment) else {
            DDLogError("⛔️ Jetpack AI JWT payload is not valid base64url")
            throw AssistantError(kind: .auth, message: Localization.invalidJWT)
        }
        let decoded: Payload
        do {
            decoded = try JSONDecoder().decode(Payload.self, from: payloadData)
        } catch {
            DDLogError("⛔️ Jetpack AI JWT payload is not valid JSON: \(error)")
            throw AssistantError(kind: .auth, message: Localization.invalidJWT)
        }
        guard let blogID = decoded.blogID else {
            DDLogError("⛔️ Jetpack AI JWT payload is missing blog_id")
            throw AssistantError(kind: .auth, message: Localization.invalidJWT)
        }
        guard let exp = decoded.exp else {
            DDLogError("⛔️ Jetpack AI JWT payload is missing exp")
            throw AssistantError(kind: .auth, message: Localization.invalidJWT)
        }
        self.token = token
        self.blogID = blogID
        self.expiresAt = Date(timeIntervalSince1970: TimeInterval(exp))
    }

    func matchesBlog(_ id: Int64) -> Bool {
        blogID == id
    }

    // 60s clock-skew margin avoids 401-then-retry cycles at the expiry boundary.
    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }

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
