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
        sut.limiter.recordFailure()

        // When
        try await sut.session.signIn(withPIN: "1234")

        // Then
        #expect(sut.session.currentStaff == staff)
        #expect(sut.session.isLocked == false)
        try sut.limiter.checkAllowed()
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
        let nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator, now: { nowValue })
        for _ in 0..<4 {
            sut.limiter.recordFailure()
        }

        // When
        var thrown: POSAuthError?
        do {
            try await sut.session.signIn(withPIN: "0000")
        } catch {
            thrown = error
        }

        // Then
        #expect(thrown == .rateLimited(until: nowValue.addingTimeInterval(30)))
    }

    @Test func test_signIn_when_failure_crosses_permanent_threshold_then_throws_permanentlyLocked() async {
        // Given
        var nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator, now: { nowValue })
        for _ in 0..<14 {
            sut.limiter.recordFailure()
        }
        nowValue = nowValue.addingTimeInterval(301)

        // When / Then
        await #expect(throws: POSAuthError.permanentlyLocked) {
            try await sut.session.signIn(withPIN: "0000")
        }
    }

    @Test func test_signIn_when_already_rate_limited_then_throws_without_calling_authenticator() async {
        // Given
        let nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator, now: { nowValue })
        for _ in 0..<5 {
            sut.limiter.recordFailure()
        }

        // When
        var thrown: POSAuthError?
        do {
            try await sut.session.signIn(withPIN: "0000")
        } catch {
            thrown = error
        }

        // Then
        #expect(thrown == .rateLimited(until: nowValue.addingTimeInterval(30)))
        #expect(authenticator.authenticatedPINs.isEmpty)
    }

    @Test func test_signIn_when_permanently_locked_then_throws_without_calling_authenticator() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let sut = makeSUT(authenticator: authenticator)
        for _ in 0..<15 {
            sut.limiter.recordFailure()
        }

        // When / Then
        await #expect(throws: POSAuthError.permanentlyLocked) {
            try await sut.session.signIn(withPIN: "0000")
        }
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

        try sut.limiter.checkAllowed()
    }

    @Test func test_lock_when_called_then_sets_isLocked_true_and_keeps_currentStaff() async throws {
        // Given
        let staff = makeStaff()
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When
        sut.session.lock()

        // Then
        #expect(sut.session.isLocked == true)
        #expect(sut.session.currentStaff == staff)
    }

    @Test func test_requestManagerApproval_when_authenticator_fails_then_throws_unknown() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(verifyResult: .failure(.unknown))
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
}

private extension DefaultPOSAccessSessionTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
        let scope: UserDefaultsTestScope
    }

    func makeSUT(authenticator: POSPINAuthenticating,
                 credentials: Result<[POSPINCredential], POSPINStoreError>? = nil,
                 now: @escaping () -> Date = { Date() }) -> SUT {
        let scope = UserDefaultsTestScope()
        let limiter = POSLocalRateLimiter(siteID: 123, userDefaults: scope.defaults, now: now)
        let session = DefaultPOSAccessSession(
            siteID: 123,
            authenticator: authenticator,
            rateLimiter: limiter,
            credentialProvider: MockPOSPINCredentialProvider(credentialsResult: credentials ?? .success([makeAdminCredential()])),
            userDefaults: scope.defaults
        )
        return SUT(session: session, limiter: limiter, scope: scope)
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
