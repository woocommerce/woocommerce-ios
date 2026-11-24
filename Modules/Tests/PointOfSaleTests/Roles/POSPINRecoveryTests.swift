import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPINRecoveryTests {
    private let siteID: Int64 = 123

    @Test func test_recoverAdminAccess_when_verified_during_wait_then_unlocks_as_admin_and_resets_attempts() async throws {
        // Given
        let sut = await makeWaitingSUT()
        let recovery = MockPOSPINRecovery(result: .verified(siteID: siteID))

        // When
        let result = await sut.session.recoverAdminAccess(using: recovery.authenticate)

        // Then
        #expect(result == .verified(siteID: siteID))
        #expect(recovery.requestedSiteIDs == [siteID])
        #expect(sut.session.isLocked == false)
        #expect(sut.session.currentStaff == POSLocalRole.admin.staff)
        #expect(sut.defaults.bool(forKey: POSLockStateKey.key(for: siteID)) == false)
        try await sut.limiter.checkAllowed(token: sut.limiter.sessionTokens.current())
    }

    @Test(arguments: [POSPINRecoveryResult.canceled, .failed, .verified(siteID: 456)])
    func test_recoverAdminAccess_when_not_verified_for_this_store_then_keeps_lock_and_wait(result: POSPINRecoveryResult) async {
        // Given
        let sut = await makeWaitingSUT()

        // When
        let outcome = await sut.session.recoverAdminAccess { _ in result }

        // Then
        #expect(outcome == (result == .canceled ? .canceled : .failed))
        #expect(sut.session.isLocked)
        #expect(!sut.session.hasPendingAdminPINChange)
        #expect(sut.session.currentStaff == nil)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) {
            try await sut.limiter.checkAllowed(token: sut.limiter.sessionTokens.current())
        }
    }

    @Test func test_recoverAdminAccess_when_lock_changes_during_sign_in_then_stale_result_cannot_unlock_or_reset() async {
        // Given
        let sut = await makeWaitingSUT()
        let recovery = MockPOSPINRecovery(result: .verified(siteID: siteID))
        recovery.onAuthenticate = { sut.session.lock() }

        // When
        let result = await sut.session.recoverAdminAccess(using: recovery.authenticate)

        // Then
        #expect(result == .failed)
        #expect(sut.session.isLocked)
        #expect(sut.session.currentStaff == nil)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) {
            try await sut.limiter.checkAllowed(token: sut.limiter.sessionTokens.current())
        }
    }

    @Test func test_recoverAdminAccess_when_unlocked_then_does_not_ask_for_sign_in() async throws {
        // Given
        let sut = makeSUT()
        try await sut.session.signIn(withPIN: "1234")
        let recovery = MockPOSPINRecovery(result: .verified(siteID: siteID))

        // When
        let result = await sut.session.recoverAdminAccess(using: recovery.authenticate)

        // Then
        #expect(result == .failed)
        #expect(recovery.requestedSiteIDs.isEmpty)
    }

    @Test func test_recoverAdminAccess_when_session_ends_during_sign_in_then_keeps_lock_and_wait() async {
        // Given
        let sut = await makeWaitingSUT()

        // When
        let result = await sut.session.recoverAdminAccess { siteID in
            sut.session.endSession()
            return .verified(siteID: siteID)
        }

        // Then
        #expect(result == .failed)
        #expect(sut.session.isLocked)
        #expect(sut.session.currentStaff == nil)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) {
            try await sut.limiter.checkAllowed(token: sut.limiter.sessionTokens.current())
        }
    }
}

private extension POSPINRecoveryTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
        let defaults: UserDefaults
    }

    func makeSUT() -> SUT {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)") ?? .standard
        let credential = POSPINCredential(staff: POSLocalRole.admin.staff,
                                          pinHash: POSPINHash(algorithm: "pbkdf2-sha256", iterations: 1, salt: Data([1]), hash: Data([2])))
        let limiter = POSLocalRateLimiter(siteID: siteID, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock())
        let session = DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: MockPOSPINAuthenticator(authenticateResult: .success(POSLocalRole.admin.staff)),
            rateLimiter: limiter,
            credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .success([credential])),
            userDefaults: defaults
        )
        return SUT(session: session, limiter: limiter, defaults: defaults)
    }

    /// Five wrong PINs start a 30-second wait.
    func makeWaitingSUT() async -> SUT {
        let sut = makeSUT()
        let token = sut.limiter.sessionTokens.current()
        let wrong = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        for _ in 0..<5 {
            _ = try? await sut.limiter.authenticate(pin: "0000", using: wrong, token: token)
        }
        return sut
    }
}

@MainActor
private final class MockPOSPINRecovery {
    let result: POSPINRecoveryResult
    var onAuthenticate: (() -> Void)?
    private(set) var requestedSiteIDs: [Int64] = []

    init(result: POSPINRecoveryResult) {
        self.result = result
    }

    func authenticate(siteID: Int64) async -> POSPINRecoveryResult {
        requestedSiteIDs.append(siteID)
        onAuthenticate?()
        return result
    }
}
