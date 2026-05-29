import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct CachedJWTTests {

    @Test
    func test_init_when_token_has_one_segment_then_throws_auth_error() {
        // When / Then
        #expect(throws: AssistantError.self) {
            _ = try CachedJWT(token: "only-one-segment")
        }
    }

    @Test
    func test_init_when_token_payload_is_not_base64url_then_throws_auth_error() {
        // When / Then
        #expect(throws: AssistantError.self) {
            _ = try CachedJWT(token: "header.\u{1F600}.signature")
        }
    }

    @Test
    func test_init_when_token_payload_is_not_json_then_throws_auth_error() {
        // Given the literal "not-json" in base64url
        let header = Self.base64URLEncode(Data("header".utf8))
        let payload = Self.base64URLEncode(Data("not-json".utf8))
        let token = "\(header).\(payload).signature"

        // When / Then
        #expect(throws: AssistantError.self) {
            _ = try CachedJWT(token: token)
        }
    }

    @Test
    func test_init_when_payload_missing_blog_id_then_throws_auth_error() {
        // Given
        let token = Self.makeToken(payload: "{\"exp\":\(Int(Date().timeIntervalSince1970) + 3600)}")

        // When / Then
        #expect(throws: AssistantError.self) {
            _ = try CachedJWT(token: token)
        }
    }

    @Test
    func test_init_when_payload_missing_exp_then_throws_auth_error() {
        // Given
        let token = Self.makeToken(payload: "{\"blog_id\":12345}")

        // When / Then
        #expect(throws: AssistantError.self) {
            _ = try CachedJWT(token: token)
        }
    }

    @Test
    func test_init_when_payload_well_formed_then_extracts_blog_id_and_expiry() throws {
        // Given
        let exp = Int(Date().timeIntervalSince1970) + 3600
        let token = Self.makeToken(payload: "{\"blog_id\":42,\"exp\":\(exp)}")

        // When
        let cached = try CachedJWT(token: token)

        // Then
        #expect(cached.blogID == 42)
        #expect(cached.expiresAt.timeIntervalSince1970 == TimeInterval(exp))
        #expect(cached.matchesBlog(42))
    }

    private static func makeToken(payload: String) -> String {
        let header = base64URLEncode(Data(#"{"alg":"HS256","typ":"JWT"}"#.utf8))
        let payloadEncoded = base64URLEncode(Data(payload.utf8))
        return "\(header).\(payloadEncoded).signature"
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
