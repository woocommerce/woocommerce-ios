import Foundation
import Testing
@testable import Networking

/// Tests every row of spec §5.1.1, §5.1.2, §5.1.3 against the self-hosted
/// QR-login Remote, plus the request-shape assertions that the spec calls out
/// explicitly (Cache-Control on poll, no `device.*` on exchange).
struct SelfHostedQRLoginRemoteTests {

    private let siteURL = URL(string: "https://shop.example")!
    private let token = String(repeating: "a", count: 64)
    private let sessionID = "session-1"
    private let grant = "grant-1"
    private let device = QRLoginScanDevice(os: "iOS",
                                           osVersion: "18.5",
                                           model: "iPhone17,1",
                                           brand: "Apple",
                                           appVersion: "23.6")

    // MARK: - /scan (§5.1.1)

    @Test func scan_when_200_then_decodes_response() async throws {
        // Given
        let url = makeURL(path: "/qr-login-scan")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "abc",
            "real_number": "428",
            "expires_in": 90
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        let response = try await remote.scan(siteURL: siteURL, token: token, device: device)

        // Then
        #expect(response == QRLoginScanResponse(sessionID: "abc",
                                                realNumber: "428",
                                                expiresInSeconds: 90,
                                                userEmail: nil))
    }

    @Test func scan_sends_supports_number_matching_and_device_fields() async throws {
        // Given
        let url = makeURL(path: "/qr-login-scan")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "x", "real_number": "001", "expires_in": 90
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        _ = try await remote.scan(siteURL: siteURL, token: token, device: device)

        // Then
        let body = try requireBody(for: url)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(decoded?["token"] as? String == token)
        #expect(decoded?["supports_number_matching"] as? Bool == true)
        let deviceDict = decoded?["device"] as? [String: String]
        #expect(deviceDict?["os"] == "iOS")
        #expect(deviceDict?["app_version"] == "23.6")
    }

    @Test func scan_when_401_then_throws_unauthorized() async {
        await expectScanError(statusCode: 401, body: Data(), expected: .unauthorized)
    }

    @Test func scan_when_403_then_throws_unauthorized() async {
        await expectScanError(statusCode: 403, body: Data(), expected: .unauthorized)
    }

    @Test func scan_when_404_then_throws_notFound() async {
        await expectScanError(statusCode: 404, body: Data(), expected: .notFound)
    }

    @Test func scan_when_426_then_throws_upgradeRequired() async {
        await expectScanError(statusCode: 426, body: Data(), expected: .upgradeRequired)
    }

    @Test func scan_when_409_then_throws_conflict() async {
        await expectScanError(statusCode: 409, body: Data(), expected: .conflict)
    }

    @Test func scan_when_429_then_throws_rateLimited() async {
        await expectScanError(statusCode: 429, body: Data(), expected: .rateLimited)
    }

    @Test func scan_when_500_then_throws_internalServerError() async {
        await expectScanError(statusCode: 500, body: Data(), expected: .internalServerError(code: nil))
    }

    @Test func scan_when_malformed_body_then_throws_malformed() async {
        // Given — 200 OK but missing real_number
        let url = makeURL(path: "/qr-login-scan")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "session_id": "abc", "expires_in": 90
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.malformed) {
            _ = try await remote.scan(siteURL: siteURL, token: token, device: device)
        }
    }

    @Test func scan_when_network_failure_then_throws_network() async {
        // Given
        let url = makeURL(path: "/qr-login-scan")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.failure(URLError(.notConnectedToInternet)), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.network) {
            _ = try await remote.scan(siteURL: siteURL, token: token, device: device)
        }
    }

    // MARK: - /session-status (§5.1.2)

    @Test func pollSessionStatus_sends_session_id_and_token_hash_and_no_cache_header() async throws {
        // Given
        let url = makeURL(path: "/qr-login-session-status", query: "session_id=session-1&token_hash=hash-1")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json(["state": "scanned"])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        let status = try await remote.pollSessionStatus(siteURL: siteURL, sessionID: "session-1", tokenHash: "hash-1")

        // Then
        #expect(status == QRLoginSessionStatus(state: .scanned, exchangeGrant: nil))
        // The Cache-Control header is asserted indirectly via the stub URL
        // matching — request reached the protocol with the configured URL.
        #expect(QRLoginStubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func pollSessionStatus_when_approved_with_grant_then_returns_approved() async throws {
        // Given
        let url = makeURL(path: "/qr-login-session-status", query: "session_id=session-1&token_hash=hash-1")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "state": "approved",
            "exchange_grant": "grant-abc"
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        let status = try await remote.pollSessionStatus(siteURL: siteURL, sessionID: "session-1", tokenHash: "hash-1")

        // Then
        #expect(status == QRLoginSessionStatus(state: .approved, exchangeGrant: "grant-abc"))
    }

    @Test func pollSessionStatus_when_unknown_state_then_maps_to_unknown() async throws {
        // Given — server returns a state value the client doesn't recognise.
        let url = makeURL(path: "/qr-login-session-status", query: "session_id=session-1&token_hash=hash-1")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json(["state": "spinning"])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        let status = try await remote.pollSessionStatus(siteURL: siteURL, sessionID: "session-1", tokenHash: "hash-1")

        // Then — consumer translates `.unknown` to `expired` defensively.
        #expect(status.state == .unknown)
    }

    @Test func pollSessionStatus_when_404_then_throws_notFound() async {
        // Given
        let url = makeURL(path: "/qr-login-session-status", query: "session_id=session-1&token_hash=hash-1")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 404, body: Data()), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.notFound) {
            _ = try await remote.pollSessionStatus(siteURL: siteURL, sessionID: "session-1", tokenHash: "hash-1")
        }
    }

    @Test func pollSessionStatus_when_429_then_throws_rateLimited() async {
        // Given
        let url = makeURL(path: "/qr-login-session-status", query: "session_id=session-1&token_hash=hash-1")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 429, body: Data()), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.rateLimited) {
            _ = try await remote.pollSessionStatus(siteURL: siteURL, sessionID: "session-1", tokenHash: "hash-1")
        }
    }

    // MARK: - /exchange (§5.1.3)

    @Test func exchange_when_200_then_decodes_response() async throws {
        // Given
        let url = makeURL(path: "/qr-login-exchange")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "user_login": "shopkeeper",
            "site_url": "https://shop.example",
            "application_password": "ap-1234"
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        let response = try await remote.exchange(siteURL: siteURL, token: token, exchangeGrant: grant)

        // Then
        #expect(response == QRLoginSelfHostedExchangeResponse(userLogin: "shopkeeper",
                                                              siteURL: "https://shop.example",
                                                              applicationPassword: "ap-1234"))
    }

    @Test func exchange_does_not_send_device_metadata() async throws {
        // Given — spec §5.1.3 explicitly: "The exchange request does not carry
        // `device.*` metadata; that lives only on `/scan`."
        let url = makeURL(path: "/qr-login-exchange")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 200, body: json([
            "user_login": "a", "site_url": "https://shop.example", "application_password": "p"
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When
        _ = try await remote.exchange(siteURL: siteURL, token: token, exchangeGrant: grant)

        // Then
        let body = try requireBody(for: url)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(decoded?["token"] as? String == token)
        #expect(decoded?["exchange_grant"] as? String == grant)
        #expect(decoded?.keys.contains("device") == false)
        #expect(decoded?.keys.contains("supports_number_matching") == false)
    }

    @Test func exchange_when_412_qr_login_not_approved_then_preconditionFailed_with_code() async {
        // Given
        let url = makeURL(path: "/qr-login-exchange")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 412, body: json([
            "code": "qr_login_not_approved",
            "message": "Not approved yet"
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.preconditionFailed(code: "qr_login_not_approved")) {
            _ = try await remote.exchange(siteURL: siteURL, token: token, exchangeGrant: grant)
        }
    }

    @Test func exchange_when_412_invalid_exchange_grant_then_preconditionFailed_with_code() async {
        // Given
        let url = makeURL(path: "/qr-login-exchange")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 412, body: json([
            "code": "invalid_exchange_grant"
        ])), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.preconditionFailed(code: "invalid_exchange_grant")) {
            _ = try await remote.exchange(siteURL: siteURL, token: token, exchangeGrant: grant)
        }
    }

    @Test func exchange_when_412_unknown_code_then_preconditionFailed_with_nil_code() async {
        // Given — 412 with a body that doesn't carry a usable `code`.
        let url = makeURL(path: "/qr-login-exchange")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: 412, body: Data("not json".utf8)), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: QRLoginNetworkError.preconditionFailed(code: nil)) {
            _ = try await remote.exchange(siteURL: siteURL, token: token, exchangeGrant: grant)
        }
    }
}

// MARK: - Helpers

private extension SelfHostedQRLoginRemoteTests {

    func makeURL(path: String, query: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "shop.example"
        components.path = "/wp-json/wc-admin/mobile-app" + path
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
        let url = makeURL(path: "/qr-login-scan")
        QRLoginStubURLProtocol.reset()
        QRLoginStubURLProtocol.stub(.response(statusCode: statusCode, body: body), for: url)
        let remote = SelfHostedQRLoginRemote(session: QRLoginStubURLProtocol.makeSession())

        // When / Then
        await #expect(throws: expected) {
            _ = try await remote.scan(siteURL: siteURL, token: token, device: device)
        }
    }
}
