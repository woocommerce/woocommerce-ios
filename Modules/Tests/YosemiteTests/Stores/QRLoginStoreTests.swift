import Foundation
import Testing
import Networking
@testable import Yosemite

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct QRLoginStoreTests {

    // MARK: - Self-hosted dispatch

    @Test func selfHostedScan_dispatch_forwards_to_remote_and_returns_response() async {
        // Given
        let expected = SelfHostedQRLoginScanResponse(sessionID: "s", realNumber: "123", expiresInSeconds: 90)
        let selfHosted = MockSelfHostedQRLoginRemote()
        selfHosted.scanResponse = .success(expected)
        let store = makeStore(selfHosted: selfHosted)

        // When
        let response = await dispatchScanSelfHosted(store: store)

        // Then
        #expect((try? response.get()) == expected)
        #expect(selfHosted.scanCalls.count == 1)
        #expect(selfHosted.scanCalls.first?.token == "token-a")
    }

    @Test func selfHostedScan_dispatch_propagates_remote_error() async {
        // Given
        let selfHosted = MockSelfHostedQRLoginRemote()
        selfHosted.scanResponse = .failure(.upgradeRequired)
        let store = makeStore(selfHosted: selfHosted)

        // When
        let response = await dispatchScanSelfHosted(store: store)

        // Then
        if case .failure(let error) = response {
            #expect(error == .upgradeRequired)
        } else {
            Issue.record("Expected failure(.upgradeRequired), got \(response)")
        }
    }

    @Test func selfHostedPoll_dispatch_forwards_session_id_and_token_hash() async {
        // Given
        let selfHosted = MockSelfHostedQRLoginRemote()
        selfHosted.pollResponse = .success(.init(state: .scanned, exchangeGrant: nil))
        let store = makeStore(selfHosted: selfHosted)

        // When
        _ = await withCheckedContinuation { continuation in
            let action = QRLoginAction.selfHostedPoll(
                siteURL: URL(string: "https://shop.example")!,
                sessionID: "session-x",
                tokenHash: "hash-x"
            ) { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }

        // Then
        #expect(selfHosted.pollCalls.count == 1)
        #expect(selfHosted.pollCalls.first?.sessionID == "session-x")
        #expect(selfHosted.pollCalls.first?.tokenHash == "hash-x")
    }

    @Test func selfHostedExchange_dispatch_forwards_to_remote() async {
        // Given
        let expected = SelfHostedQRLoginExchangeResponse(userLogin: "u",
                                                         siteURL: "https://shop.example",
                                                         applicationPassword: "ap")
        let selfHosted = MockSelfHostedQRLoginRemote()
        selfHosted.exchangeResponse = .success(expected)
        let store = makeStore(selfHosted: selfHosted)

        // When
        let response = await withCheckedContinuation { continuation in
            let action = QRLoginAction.selfHostedExchange(
                siteURL: URL(string: "https://shop.example")!,
                token: "token-a",
                exchangeGrant: "grant-a"
            ) { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }

        // Then
        #expect((try? response.get()) == expected)
        #expect(selfHosted.exchangeCalls.first?.exchangeGrant == "grant-a")
    }

    // MARK: - WP.com dispatch

    @Test func wpComScan_dispatch_forwards_to_remote() async {
        // Given
        let expected = WPComQRLoginScanResponse(sessionID: "s", realNumber: "123", expiresInSeconds: 90, userEmail: "u@e")
        let wpCom = MockWPComQRLoginRemote()
        wpCom.scanResponse = .success(expected)
        let store = makeStore(wpCom: wpCom)

        // When
        let response = await withCheckedContinuation { continuation in
            let action = QRLoginAction.wpComScan(token: "compound", encrypted: "blob", device: device) { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }

        // Then
        #expect((try? response.get()) == expected)
        #expect(wpCom.scanCalls.first?.token == "compound")
        #expect(wpCom.scanCalls.first?.encrypted == "blob")
    }

    @Test func wpComPoll_dispatch_returns_coerced_expired_when_remote_returns_expired() async {
        // Given — wp.com Remote handles the 404→expired coercion itself; the
        // Store just forwards what comes back.
        let wpCom = MockWPComQRLoginRemote()
        wpCom.pollResponse = .success(.init(state: .expired, exchangeGrant: nil))
        let store = makeStore(wpCom: wpCom)

        // When
        let response = await withCheckedContinuation { continuation in
            let action = QRLoginAction.wpComPoll(sessionID: "s", tokenHash: "h") { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }

        // Then
        #expect((try? response.get())?.state == .expired)
    }

    @Test func wpComExchange_dispatch_forwards_to_remote() async {
        // Given
        let expected = WPComQRLoginExchangeResponse(magicLinkURL: URL(string: "https://wordpress.com/wp-login.php?token=x")!)
        let wpCom = MockWPComQRLoginRemote()
        wpCom.exchangeResponse = .success(expected)
        let store = makeStore(wpCom: wpCom)

        // When
        let response = await withCheckedContinuation { continuation in
            let action = QRLoginAction.wpComExchange(token: "compound", encrypted: "blob", exchangeGrant: "g") { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }

        // Then
        #expect((try? response.get()) == expected)
        #expect(wpCom.exchangeCalls.first?.exchangeGrant == "g")
    }
}

// MARK: - Helpers

private let device = QRLoginScanDevice(os: "iOS",
                                       osVersion: "18.5",
                                       model: "iPhone17,1",
                                       brand: "Apple",
                                       appVersion: "23.6")

private extension QRLoginStoreTests {

    func makeStore(selfHosted: SelfHostedQRLoginRemoteProtocol = MockSelfHostedQRLoginRemote(),
                   wpCom: WPComQRLoginRemoteProtocol = MockWPComQRLoginRemote()) -> QRLoginStore {
        QRLoginStore(dispatcher: Dispatcher(), selfHostedRemote: selfHosted, wpComRemote: wpCom)
    }

    func dispatchScanSelfHosted(store: QRLoginStore) async -> Result<SelfHostedQRLoginScanResponse, QRLoginNetworkError> {
        await withCheckedContinuation { continuation in
            let action = QRLoginAction.selfHostedScan(
                siteURL: URL(string: "https://shop.example")!,
                token: "token-a",
                device: device
            ) { result in
                continuation.resume(returning: result)
            }
            store.onAction(action)
        }
    }
}

// MARK: - Mocks

private final class MockSelfHostedQRLoginRemote: SelfHostedQRLoginRemoteProtocol, @unchecked Sendable {
    struct ScanCall { let siteURL: URL; let token: String; let device: QRLoginScanDevice }
    struct PollCall { let siteURL: URL; let sessionID: String; let tokenHash: String }
    struct ExchangeCall { let siteURL: URL; let token: String; let exchangeGrant: String }

    var scanCalls: [ScanCall] = []
    var pollCalls: [PollCall] = []
    var exchangeCalls: [ExchangeCall] = []

    var scanResponse: Result<SelfHostedQRLoginScanResponse, QRLoginNetworkError> = .failure(.malformed)
    var pollResponse: Result<SelfHostedQRLoginSessionStatus, QRLoginNetworkError> = .failure(.malformed)
    var exchangeResponse: Result<SelfHostedQRLoginExchangeResponse, QRLoginNetworkError> = .failure(.malformed)

    func scan(siteURL: URL, token: String, device: QRLoginScanDevice) async throws -> SelfHostedQRLoginScanResponse {
        scanCalls.append(.init(siteURL: siteURL, token: token, device: device))
        return try scanResponse.get()
    }

    func pollSessionStatus(siteURL: URL, sessionID: String, tokenHash: String) async throws -> SelfHostedQRLoginSessionStatus {
        pollCalls.append(.init(siteURL: siteURL, sessionID: sessionID, tokenHash: tokenHash))
        return try pollResponse.get()
    }

    func exchange(siteURL: URL, token: String, exchangeGrant: String) async throws -> SelfHostedQRLoginExchangeResponse {
        exchangeCalls.append(.init(siteURL: siteURL, token: token, exchangeGrant: exchangeGrant))
        return try exchangeResponse.get()
    }
}

private final class MockWPComQRLoginRemote: WPComQRLoginRemoteProtocol, @unchecked Sendable {
    struct ScanCall { let token: String; let encrypted: String; let device: QRLoginScanDevice }
    struct PollCall { let sessionID: String; let tokenHash: String }
    struct ExchangeCall { let token: String; let encrypted: String; let exchangeGrant: String }

    var scanCalls: [ScanCall] = []
    var pollCalls: [PollCall] = []
    var exchangeCalls: [ExchangeCall] = []

    var scanResponse: Result<WPComQRLoginScanResponse, QRLoginNetworkError> = .failure(.malformed)
    var pollResponse: Result<WPComQRLoginSessionStatus, QRLoginNetworkError> = .failure(.malformed)
    var exchangeResponse: Result<WPComQRLoginExchangeResponse, QRLoginNetworkError> = .failure(.malformed)

    func scan(token: String, encrypted: String, device: QRLoginScanDevice) async throws -> WPComQRLoginScanResponse {
        scanCalls.append(.init(token: token, encrypted: encrypted, device: device))
        return try scanResponse.get()
    }

    func pollSessionStatus(sessionID: String, tokenHash: String) async throws -> WPComQRLoginSessionStatus {
        pollCalls.append(.init(sessionID: sessionID, tokenHash: tokenHash))
        return try pollResponse.get()
    }

    func exchange(token: String, encrypted: String, exchangeGrant: String) async throws -> WPComQRLoginExchangeResponse {
        exchangeCalls.append(.init(token: token, encrypted: encrypted, exchangeGrant: exchangeGrant))
        return try exchangeResponse.get()
    }
}
