import Foundation
import Testing
@testable import Networking

/// Covers every row of spec §5.2.1 / §5.2.2 / §5.2.3 against the WP.com
/// QR-login Remote, plus the protocol-specific behaviours called out in the
/// spec: `client_id` / `client_secret` on every request, poll 404 coerced to
/// `expired`, and the legacy `status` field name accepted in place of `state`.
@Suite(.serialized)
struct WPComQRLoginRemoteTests {

    private let clientID = "55584"
    private let clientSecret = "secret"
    private let compoundToken = "\(String(repeating: "a", count: 64)):\(String(repeating: "b", count: 32))"
    private let encrypted = "blob"
    private let sessionID = "wpcom-session"
    private let grant = "wpcom-grant"
    private let device = QRLoginScanDevice(os: "iOS",
                                           osVersion: "18.5",
                                           model: "iPhone17,1",
                                           brand: "Apple",
                                           appVersion: "23.6")

    // MARK: - /scan (§5.2.1)

    @Test func scan_when_200_then_decodes_response_with_user_email() async throws {
        // Given
        let url = makeURL(path: "/scan")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "wpcom-1",
            "real_number": "713",
            "expires_in": 90,
            "user_email": "user@example.com"
        ])), for: url)
        let remote = makeRemote()

        // When
        let response = try await remote.scan(token: compoundToken, encrypted: encrypted, device: device)

        // Then
        #expect(response == QRLoginScanResponse(sessionID: "wpcom-1",
                                                realNumber: "713",
                                                expiresInSeconds: 90,
                                                userEmail: "user@example.com"))
    }

    @Test func scan_when_user_email_missing_then_malformed() async {
        // Given
        let url = makeURL(path: "/scan")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "x", "real_number": "001", "expires_in": 90
        ])), for: url)
        let remote = makeRemote()

        // When / Then
        await #expect(throws: QRLoginNetworkError.malformed) {
            _ = try await remote.scan(token: self.compoundToken, encrypted: self.encrypted, device: self.device)
        }
    }

    @Test func scan_sends_client_credentials_token_encrypted_and_device() async throws {
        // Given
        let url = makeURL(path: "/scan")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "x", "real_number": "001", "expires_in": 90, "user_email": "u@e"
        ])), for: url)
        let remote = makeRemote()

        // When
        _ = try await remote.scan(token: compoundToken, encrypted: encrypted, device: device)

        // Then
        let body = try requireBody(for: url)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(decoded?["client_id"] as? String == clientID)
        #expect(decoded?["client_secret"] as? String == clientSecret)
        #expect(decoded?["token"] as? String == compoundToken)
        #expect(decoded?["encrypted"] as? String == encrypted)
        #expect(decoded?["supports_number_matching"] as? Bool == true)
        #expect((decoded?["device"] as? [String: String])?["os"] == "iOS")
    }

    @Test func scan_when_403_then_throws_unauthorized() async {
        await expectScanError(statusCode: 403, body: Data(), expected: .unauthorized)
    }

    @Test func scan_when_404_then_throws_notFound() async {
        await expectScanError(statusCode: 404, body: Data(), expected: .notFound)
    }

    @Test func scan_when_409_then_throws_conflict() async {
        await expectScanError(statusCode: 409, body: Data(), expected: .conflict)
    }

    @Test func scan_when_400_no_number_matching_then_badRequest_with_code() async {
        await expectScanError(
            statusCode: 400,
            body: try! JSONSerialization.data(withJSONObject: ["code": "no_number_matching"]),
            expected: .badRequest(code: "no_number_matching")
        )
    }

    @Test func scan_when_429_then_throws_rateLimited() async {
        await expectScanError(statusCode: 429, body: Data(), expected: .rateLimited)
    }

    // MARK: - /session-status (§5.2.2)

    @Test func pollSessionStatus_sends_client_credentials_session_id_and_token_hash() async throws {
        // Given
        let url = makeURL(
            path: "/session-status",
            query: "client_id=\(clientID)&client_secret=\(clientSecret)&session_id=\(sessionID)&token_hash=hash-1"
        )
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json(["state": "scanned"])), for: url)
        let remote = makeRemote()

        // When
        let status = try await remote.pollSessionStatus(sessionID: sessionID, tokenHash: "hash-1")

        // Then
        #expect(status == QRLoginSessionStatus(state: .scanned, exchangeGrant: nil))
        #expect(QRLoginStubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func pollSessionStatus_when_status_field_used_in_place_of_state_then_still_decodes() async throws {
        // Given — wp.com legacy alias (§5.2.2).
        let url = makeURL(
            path: "/session-status",
            query: "client_id=\(clientID)&client_secret=\(clientSecret)&session_id=\(sessionID)&token_hash=hash-1"
        )
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json(["status": "approved", "exchange_grant": "g"])), for: url)
        let remote = makeRemote()

        // When
        let status = try await remote.pollSessionStatus(sessionID: sessionID, tokenHash: "hash-1")

        // Then
        #expect(status == QRLoginSessionStatus(state: .approved, exchangeGrant: "g"))
    }

    @Test func pollSessionStatus_when_consumed_then_returns_consumed_state() async throws {
        // Given
        let url = makeURL(
            path: "/session-status",
            query: "client_id=\(clientID)&client_secret=\(clientSecret)&session_id=\(sessionID)&token_hash=hash-1"
        )
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json(["state": "consumed"])), for: url)
        let remote = makeRemote()

        // When
        let status = try await remote.pollSessionStatus(sessionID: sessionID, tokenHash: "hash-1")

        // Then
        #expect(status.state == .consumed)
    }

    @Test func pollSessionStatus_when_404_then_coerced_to_expired_terminal() async throws {
        // Given — spec §5.2.2: wp.com poll 404 → expired terminal, not surfaced
        // as a hard error.
        let url = makeURL(
            path: "/session-status",
            query: "client_id=\(clientID)&client_secret=\(clientSecret)&session_id=\(sessionID)&token_hash=hash-1"
        )
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 404, body: Data()), for: url)
        let remote = makeRemote()

        // When
        let status = try await remote.pollSessionStatus(sessionID: sessionID, tokenHash: "hash-1")

        // Then
        #expect(status == QRLoginSessionStatus(state: .expired, exchangeGrant: nil))
    }

    @Test func pollSessionStatus_when_403_then_throws_unauthorized() async {
        // Given — wp.com poll 403 = token_hash mismatch; terminal "Code expired".
        let url = makeURL(
            path: "/session-status",
            query: "client_id=\(clientID)&client_secret=\(clientSecret)&session_id=\(sessionID)&token_hash=hash-1"
        )
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 403, body: Data()), for: url)
        let remote = makeRemote()

        // When / Then
        await #expect(throws: QRLoginNetworkError.unauthorized) {
            _ = try await remote.pollSessionStatus(sessionID: self.sessionID, tokenHash: "hash-1")
        }
    }

    // MARK: - /exchange (§5.2.3)

    @Test func exchange_when_200_then_decodes_magic_link_url() async throws {
        // Given
        let url = makeURL(path: "/exchange")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "magic_link_url": "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token=abc"
        ])), for: url)
        let remote = makeRemote()

        // When
        let response = try await remote.exchange(token: compoundToken, encrypted: encrypted, exchangeGrant: grant)

        // Then
        #expect(response.magicLinkURL.absoluteString.hasPrefix("https://wordpress.com/wp-login.php"))
    }

    @Test func exchange_sends_client_credentials_token_encrypted_and_grant() async throws {
        // Given
        let url = makeURL(path: "/exchange")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "magic_link_url": "https://wordpress.com/wp-login.php?token=x"
        ])), for: url)
        let remote = makeRemote()

        // When
        _ = try await remote.exchange(token: compoundToken, encrypted: encrypted, exchangeGrant: grant)

        // Then
        let body = try requireBody(for: url)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(decoded?["client_id"] as? String == clientID)
        #expect(decoded?["client_secret"] as? String == clientSecret)
        #expect(decoded?["token"] as? String == compoundToken)
        #expect(decoded?["encrypted"] as? String == encrypted)
        #expect(decoded?["exchange_grant"] as? String == grant)
        #expect(decoded?.keys.contains("device") == false)
        #expect(decoded?.keys.contains("supports_number_matching") == false)
    }

    @Test func exchange_when_412_qr_login_not_approved_then_preconditionFailed_with_code() async {
        // Given
        let url = makeURL(path: "/exchange")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 412, body: json([
            "code": "qr_login_not_approved"
        ])), for: url)
        let remote = makeRemote()

        // When / Then
        await #expect(throws: QRLoginNetworkError.preconditionFailed(code: "qr_login_not_approved")) {
            _ = try await remote.exchange(token: self.compoundToken,
                                          encrypted: self.encrypted,
                                          exchangeGrant: self.grant)
        }
    }

    @Test func exchange_when_500_already_consumed_then_internalServerError_with_code() async {
        // Given
        let url = makeURL(path: "/exchange")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: 500, body: json([
            "code": "already_consumed"
        ])), for: url)
        let remote = makeRemote()

        // When / Then
        await #expect(throws: QRLoginNetworkError.internalServerError(code: "already_consumed")) {
            _ = try await remote.exchange(token: self.compoundToken,
                                          encrypted: self.encrypted,
                                          exchangeGrant: self.grant)
        }
    }
}

// MARK: - Helpers

private extension WPComQRLoginRemoteTests {

    /// Host of the wp.com API base URL — used to scope stub resets so this
    /// suite never wipes the self-hosted suite's stubs when run in parallel.
    static var wpComHost: String {
        URL(string: Settings.wordpressApiBaseURL)?.host ?? "public-api.wordpress.com"
    }

    func makeRemote() -> WPComQRLoginRemote {
        WPComQRLoginRemote(clientID: clientID,
                           clientSecret: clientSecret,
                           session: QRLoginStubURLProtocol.makeSession())
    }

    func makeURL(path: String, query: String? = nil) -> URL {
        var components = URLComponents(string: Settings.wordpressApiBaseURL + "wpcom/v2/auth/qr-code-app" + path)!
        components.query = query
        return components.url!
    }

    func json(_ object: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func requireBody(for url: URL) throws -> Data {
        guard let body = QRLoginStubURLProtocol.capturedBody(for: url) else {
            Issue.record("Expected captured request body for \(url) but none was recorded")
            throw QRLoginNetworkError.malformed
        }
        return body
    }

    func expectScanError(statusCode: Int, body: Data, expected: QRLoginNetworkError) async {
        // Given
        let url = makeURL(path: "/scan")
        QRLoginStubURLProtocol.reset(host: Self.wpComHost)
        QRLoginStubURLProtocol.stub(.response(statusCode: statusCode, body: body), for: url)
        let remote = makeRemote()

        // When / Then
        await #expect(throws: expected) {
            _ = try await remote.scan(token: self.compoundToken, encrypted: self.encrypted, device: self.device)
        }
    }
}
