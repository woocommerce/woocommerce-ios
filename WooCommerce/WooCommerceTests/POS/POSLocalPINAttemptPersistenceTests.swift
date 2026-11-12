import Foundation
import Synchronization
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLocalPINAttemptPersistenceTests {
    @Test func test_real_keychain_when_offline_unlock_and_approval_share_budget_then_cashier_cannot_reset_guesses() async throws {
        // Given: real native storage and the production credential comparator, without a network source.
        let clock = NativePINClock()
        let native = KeychainPOSSecureStorage(service: "com.automattic.woocommerce.pos.tests." + UUID().uuidString)
        defer { try? native.removeAll() }
        let store = POSLocalPINStore(siteID: 123, storage: native, iterations: 1000)
        try await Task.detached {
            try store.setPIN("1234", for: .admin)
            try store.setPIN("5678", for: .cashier)
        }.value
        let authenticator = DefaultPOSPINAuthenticator(credentialProvider: store)
        let limiter = POSLocalRateLimiter(siteID: 123, storage: native, clock: clock)
        let token = limiter.context.current()
        for _ in 0..<4 {
            await #expect(throws: POSAuthError.invalidPIN) { try await limiter.authenticate(pin: "0000", using: authenticator, token: token) }
        }

        // When
        let cashier = try await limiter.authenticate(pin: "5678", using: authenticator, token: token)

        // Then
        #expect(cashier == POSLocalRole.cashier.staff)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) {
            try await limiter.authenticate(pin: "5678", using: authenticator, capability: .issueRefunds, token: token)
        }
        let recreated = POSLocalRateLimiter(siteID: 123, storage: native, clock: clock)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) { try await recreated.checkAllowed(token: recreated.context.current()) }
        clock.seconds += 30
        let admin = try await limiter.authenticate(pin: "1234", using: authenticator, token: token)
        #expect(admin == POSLocalRole.admin.staff)
        let stored = try await Task.detached { try native.data(forKey: "attempts.123") }.value
        let record = try JSONDecoder().decode([String: Double].self, from: #require(stored))
        #expect(record["failures"] == 0)
        try await Task.detached {
            try POSPINAttemptContext.clearAll(scopeID: native.scopeID) { try POSLocalPINStore.removeAll(storage: native) }
        }.value
        #expect(try await Task.detached { try native.data(forKey: "attempts.123") }.value == nil)
        #expect(try await Task.detached { try store.credentials().isEmpty }.value)
    }
}

private final class NativePINClock: POSPINClock, Sendable {
    private let value = Mutex<TimeInterval>(1000)
    var seconds: TimeInterval {
        get { value.withLock { $0 } }
        set { value.withLock { $0 = newValue } }
    }
    func now() throws -> TimeInterval { seconds }
}
