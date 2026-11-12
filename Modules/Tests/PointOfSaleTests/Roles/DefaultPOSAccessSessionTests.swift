import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSAccessSessionTests {
    @Test func test_signIn_when_pin_is_valid_then_sets_currentStaff_and_unlocks_and_resets_limiter() async throws {
        // Given
        let staff = makeStaff()
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        await seedFailures(1, sut: sut)

        // When
        try await sut.session.signIn(withPIN: "1234")

        // Then
        #expect(sut.session.currentStaff == staff)
        #expect(sut.session.isLocked == false)
        try await sut.limiter.checkAllowed(token: sut.limiter.context.current())
    }

    @Test func test_signIn_when_pin_is_invalid_then_throws_invalidPIN_and_records_failure() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator)

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            try await sut.session.signIn(withPIN: "0000")
        }
        #expect(authenticator.authenticatedPINs == ["0000"])
        #expect(sut.session.currentStaff == nil)
    }

    @Test func test_signIn_when_failure_crosses_30_second_threshold_then_throws_rateLimited() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator)
        for _ in 0..<4 {
            await seedFailures(1, sut: sut)
        }

        // When
        var thrown: POSAuthError?
        do {
            try await sut.session.signIn(withPIN: "0000")
        } catch {
            thrown = error
        }

        // Then
        #expect(thrown == .rateLimited(remainingSeconds: 30))
    }

    @Test func test_signIn_when_already_rate_limited_then_throws_without_calling_authenticator() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator)
        for _ in 0..<5 {
            await seedFailures(1, sut: sut)
        }

        // When
        var thrown: POSAuthError?
        do {
            try await sut.session.signIn(withPIN: "0000")
        } catch {
            thrown = error
        }

        // Then
        #expect(thrown == .rateLimited(remainingSeconds: 30))
        #expect(authenticator.authenticatedPINs.isEmpty)
    }

    @Test func test_signIn_when_authenticator_throws_unknown_then_rethrows_without_recording_failure() async throws {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.unknown))
        let sut = makeSUT(authenticator: authenticator)

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await sut.session.signIn(withPIN: "0000")
        }

        try await sut.limiter.checkAllowed(token: sut.limiter.context.current())
    }

    @Test func test_lock_when_called_then_removes_currentStaff_and_denies_access() async throws {
        // Given
        let staff = makeStaff()
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When
        sut.session.lock()

        // Then
        #expect(sut.session.isLocked == true)
        #expect(sut.session.currentStaff == nil)
        #expect(sut.session.allows(.processSales) == false)
    }

    @Test func test_requestManagerApproval_when_authenticator_fails_then_throws_unknown() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.unknown))
        let sut = makeSUT(authenticator: authenticator)

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await sut.session.requestManagerApproval(withPIN: "1234", for: .issueRefunds)
        }
    }

    @Test func test_allows_when_currentStaff_has_capability_then_returns_true() async throws {
        // Given
        let staff = makeStaff(capabilities: [.issueRefunds])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.issueRefunds) == true)
    }

    @Test func test_allows_when_currentStaff_lacks_capability_then_returns_false() async throws {
        // Given
        let staff = makeStaff(capabilities: POSLocalRole.cashier.capabilities)
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.issueRefunds) == false)
    }

    @Test func test_allows_when_gated_but_not_signed_in_then_returns_false() {
        // Given a session with an Admin PIN (gating active) but nobody signed in
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When / Then — gating is active and there's no current staff, so access is denied
        #expect(sut.session.isPINProtectionEnabled == true)
        #expect(sut.session.allows(.issueRefunds) == false)
    }

    @Test func test_allows_when_no_admin_pin_is_set_then_returns_true() {
        // Given a roles-enabled session without an Admin PIN (gating inactive)
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .success([]))

        // When / Then — nobody can sign in and no PIN could approve an override, so gating is off
        #expect(sut.session.isPINProtectionEnabled == false)
        #expect(sut.session.allows(.issueRefunds) == true)
        #expect(sut.session.allows(.exitPOS) == true)
    }

    @Test func test_lock_when_called_then_persists_true_to_per_site_lock_key() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When
        sut.session.lock()

        // Then
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == true)
    }

    @Test func test_signIn_when_pin_is_valid_then_persists_false_to_per_site_lock_key() async throws {
        // Given
        let staff = makeStaff()
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        sut.session.lock()
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == true)

        // When
        try await sut.session.signIn(withPIN: "1234")

        // Then
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
    }

    @Test func test_lock_when_called_then_does_not_pollute_other_site_lock_keys() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When
        sut.session.lock()

        // Then
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 999)) == false)
    }

    @Test func test_init_when_no_pins_are_set_then_protection_is_off_and_unlocked() {
        // Given / When
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .success([]))

        // Then
        #expect(sut.session.isPINProtectionEnabled == false)
        #expect(sut.session.isLocked == false)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
    }

    @Test func test_init_when_admin_pin_is_set_then_protection_is_on_and_locked() {
        // Given / When
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // Then
        #expect(sut.session.isPINProtectionEnabled == true)
        #expect(sut.session.isLocked == true)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == true)
    }

    @Test func test_init_when_pins_are_unreadable_then_stays_locked_and_denies_actions() {
        // Given / When
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .failure(.storageFailure))

        // Then
        #expect(sut.session.isPINProtectionEnabled == true)
        #expect(sut.session.isLocked == true)
        #expect(sut.session.allows(.processSales) == false)
        #expect(sut.session.allows(.exitPOS) == false)
    }

    @Test func test_init_when_pins_are_unreadable_then_does_not_persist_the_lock_for_cold_launch() {
        // Given / When
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .failure(.storageFailure))

        // Then
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
    }

    @Test func test_lock_when_protection_is_off_then_stays_unlocked() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .success([]))

        // When
        sut.session.lock()

        // Then
        #expect(sut.session.isLocked == false)
    }

    @Test func test_allows_when_cashier_is_signed_in_then_allows_only_cashier_capabilities() async throws {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(POSLocalRole.cashier.staff)))

        // When
        try await sut.session.signIn(withPIN: "5678")

        // Then
        #expect(sut.session.allows(.processSales))
        #expect(sut.session.allows(.issueRefunds) == false)
        #expect(sut.session.allows(.manageStoreSettings) == false)
    }
    @Test func test_lock_when_comparison_is_pending_then_late_admin_result_cannot_unlock_or_reset_budget() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        let sut = makeSUT(authenticator: authenticator)
        authenticator.onAuthenticate = { sut.session.lock() }

        // When / Then
        await #expect(throws: POSAuthError.unknown) { try await sut.session.signIn(withPIN: "1234") }
        #expect(sut.session.isLocked)
        #expect(sut.session.currentStaff == nil)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)))
    }

    @Test func test_endSession_when_comparison_is_pending_then_late_result_cannot_clear_the_lock_marker() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        let sut = makeSUT(authenticator: authenticator)
        authenticator.onAuthenticate = { sut.session.endSession() }

        // When / Then
        await #expect(throws: POSAuthError.unknown) { try await sut.session.signIn(withPIN: "1234") }
        #expect(sut.session.currentStaff == nil)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)))
    }

    @Test func test_replacement_session_when_old_comparison_completes_then_only_current_session_can_write_authority() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        let sut = makeSUT(authenticator: authenticator)
        var replacement: DefaultPOSAccessSession?
        authenticator.onAuthenticate = {
            replacement = DefaultPOSAccessSession(siteID: 123, authenticator: authenticator, rateLimiter: sut.limiter,
                                                  credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .success([makeAdminCredential()])),
                                                  userDefaults: sut.scope.defaults)
        }

        // When / Then
        await #expect(throws: POSAuthError.unknown) { try await sut.session.signIn(withPIN: "1234") }
        #expect(replacement?.isLocked == true)
        #expect(replacement?.currentStaff == nil)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)))
    }

    @Test(arguments: ["end", "lock", "refresh", "endThenRefresh"], [false, true])
    func test_old_session_when_callbacks_arrive_after_replacement_then_cannot_invalidate_new_owner(operation: String, unlockFirst: Bool) async throws {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())
        try await sut.session.signIn(withPIN: "1234")
        let replacement = DefaultPOSAccessSession(siteID: 123, authenticator: MockPOSPINAuthenticator(), rateLimiter: sut.limiter,
                                                  credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .success([makeAdminCredential()])),
                                                  userDefaults: sut.scope.defaults)
        if unlockFirst { try await replacement.signIn(withPIN: "1234") }
        let token = sut.limiter.context.current()
        #expect(sut.session.allows(.manageStoreSettings) == false)

        // When
        switch operation {
        case "end":
            sut.session.endSession()
            sut.session.endSession()
        case "lock": sut.session.lock()
        case "refresh": #expect(throws: POSPINStoreError.storageFailure) { try sut.session.refreshPINProtection() }
        default:
            sut.session.endSession()
            #expect(throws: POSPINStoreError.storageFailure) { try sut.session.refreshPINProtection() }
        }

        // Then
        #expect(sut.limiter.context.isCurrent(token))
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == !unlockFirst)
        try await replacement.checkLockoutState()
        try await replacement.signIn(withPIN: "1234")
        #expect(replacement.isLocked == false)
    }

    @Test func test_refresh_when_unprotected_session_is_replaced_then_fails_closed_locally_without_changing_new_owner() async throws {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .success([]))
        #expect(sut.session.allows(.processSales))
        let replacement = DefaultPOSAccessSession(siteID: 123, authenticator: MockPOSPINAuthenticator(), rateLimiter: sut.limiter,
                                                  credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .success([makeAdminCredential()])),
                                                  userDefaults: sut.scope.defaults)
        try await replacement.signIn(withPIN: "1234")
        let token = sut.limiter.context.current()

        // When / Then
        #expect(sut.session.allows(.processSales) == false)
        #expect(throws: POSPINStoreError.storageFailure) { try sut.session.refreshPINProtection() }
        #expect(sut.session.isLocked)
        #expect(sut.session.isPINProtectionEnabled)
        #expect(sut.limiter.context.isCurrent(token))
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        #expect(replacement.allows(.manageStoreSettings))
    }

    @Test func test_logout_when_visible_session_is_invalidated_then_late_callbacks_deny_local_access_without_recreating_marker() async throws {
        // Given
        let storage = InMemoryPOSSecureStorage()
        let limiter = POSLocalRateLimiter(siteID: 123, storage: storage, clock: MockPOSPINClock())
        let scope = UserDefaultsTestScope()
        let session = DefaultPOSAccessSession(siteID: 123, authenticator: MockPOSPINAuthenticator(), rateLimiter: limiter,
                                              credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .success([makeAdminCredential()])),
                                              userDefaults: scope.defaults)
        try await session.signIn(withPIN: "1234")
        try POSPINAttemptContext.clearAll(scopeID: storage.scopeID) { try storage.removeAll() }
        scope.defaults.removeObject(forKey: POSLockStateKey.key(for: 123))
        let token = limiter.context.current()

        // When / Then
        #expect(session.allows(.manageStoreSettings) == false)
        session.lock()
        #expect(session.isLocked)
        #expect(session.currentStaff == nil)
        #expect(throws: POSPINStoreError.storageFailure) { try session.refreshPINProtection() }
        session.endSession()
        session.lock()
        #expect(limiter.context.isCurrent(token))
        #expect(scope.defaults.object(forKey: POSLockStateKey.key(for: 123)) == nil)
    }

    @Test func test_init_when_known_locked_marker_exists_and_credentials_fail_then_preserves_marker() {
        // Given
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))

        // When
        let session = DefaultPOSAccessSession(siteID: 123, authenticator: MockPOSPINAuthenticator(),
                                              rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
                                              credentialProvider: MockPOSPINCredentialProvider(credentialsResult: .failure(.storageFailure)),
                                              userDefaults: scope.defaults)

        // Then
        #expect(session.isLocked)
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)))
    }

    @Test(arguments: [false, true])
    func test_refresh_when_credentials_fail_then_only_known_protection_creates_a_restart_marker(wasProtected: Bool) async throws {
        // Given
        let scope = UserDefaultsTestScope()
        let provider = MockPOSPINCredentialProvider(credentialsResult: .success(wasProtected ? [makeAdminCredential()] : []))
        let session = DefaultPOSAccessSession(siteID: 123, authenticator: MockPOSPINAuthenticator(),
                                              rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
                                              credentialProvider: provider, userDefaults: scope.defaults)
        if wasProtected { try await session.signIn(withPIN: "1234") }
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        provider.credentialsResult = .failure(.storageFailure)

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) { try session.refreshPINProtection() }
        #expect(session.isLocked)
        #expect(session.currentStaff == nil)
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == wasProtected)
    }

    @Test func test_refresh_when_initial_read_was_unknown_then_further_read_failure_does_not_invent_restart_marker() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), credentials: .failure(.storageFailure))

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) { try sut.session.refreshPINProtection() }
        #expect(sut.session.isLocked)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
    }
}

private extension DefaultPOSAccessSessionTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
        let scope: UserDefaultsTestScope
    }

    func makeSUT(authenticator: POSPINAuthenticating,
                 credentials: Result<[POSPINCredential], POSPINStoreError>? = nil) -> SUT {
        let scope = UserDefaultsTestScope()
        let limiter = POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock())
        let session = DefaultPOSAccessSession(
            siteID: 123,
            authenticator: authenticator,
            rateLimiter: limiter,
            credentialProvider: MockPOSPINCredentialProvider(credentialsResult: credentials ?? .success([makeAdminCredential()])),
            userDefaults: scope.defaults
        )
        return SUT(session: session, limiter: limiter, scope: scope)
    }

    func seedFailures(_ count: Int, sut: SUT) async {
        let token = sut.limiter.context.current()
        let wrong = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        for _ in 0..<count { _ = try? await sut.limiter.authenticate(pin: "0000", using: wrong, token: token) }
        try? sut.session.refreshPINProtection()
    }

    func makeAdminCredential() -> POSPINCredential {
        POSPINCredential(staff: POSLocalRole.admin.staff,
                         pinHash: POSPINHash(algorithm: "pbkdf2-sha256", iterations: 1, salt: Data([1]), hash: Data([2])))
    }

    func makeStaff(capabilities: Set<POSCapability> = Set(POSCapability.allCases)) -> POSStaff {
        POSStaff(displayName: "Staff", capabilities: capabilities)
    }
}

private final class UserDefaultsTestScope {
    let defaults: UserDefaults
    private let suiteName: String

    init() {
        suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
