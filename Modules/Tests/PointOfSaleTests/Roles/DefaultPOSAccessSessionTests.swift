import Foundation
import Testing
import struct Yosemite.POSStaffMember
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSAccessSessionTests {
    @Test func test_signIn_when_pin_is_valid_then_sets_currentStaff_and_unlocks_and_resets_limiter() async throws {
        // Given
        let staff = makeStaff(capabilities: Set(POSCapability.allCases.map(\.rawValue)))
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
        // A miss triggers one cache refresh and a single retry before giving up.
        #expect(authenticator.authenticatedPINs == ["0000", "0000"])
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

    @Test func test_requestManagerApproval_when_authenticator_succeeds_then_returns_approving_staff() async throws {
        // Given
        let approver = makeStaff(userID: 44, capabilities: [POSCapability.issueRefunds.rawValue])
        let authenticator = MockPOSPINAuthenticator(verifyResult: .success(approver))
        let sut = makeSUT(authenticator: authenticator)

        // When
        let approvedStaff = try await sut.session.requestManagerApproval(withPIN: "1234", for: .issueRefunds)

        // Then
        #expect(approvedStaff == approver)
    }

    @Test func test_allows_when_currentStaff_has_capability_then_returns_true() async throws {
        // Given
        let staff = makeStaff(capabilities: [POSCapability.issueRefunds.rawValue])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.issueRefunds) == true)
    }

    @Test func test_allows_when_currentStaff_lacks_capability_then_returns_false() async throws {
        // Given
        let staff = makeStaff(preset: "pos_cashier", capabilities: [])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.issueRefunds) == false)
    }

    @Test func test_allows_when_no_currentStaff_then_returns_false() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When / Then
        #expect(sut.session.allows(.issueRefunds) == false)
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

    @Test func test_signIn_when_pin_is_valid_then_sets_hasAnyPINs_true() async throws {
        // Given an empty cache, so gating starts off
        let staff = makeStaff()
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        #expect(sut.session.hasAnyPINs == false)
        #expect(sut.session.isLocked == false)

        // When
        try await sut.session.signIn(withPIN: "1234")

        // Then — a successful sign-in proves a PIN exists
        #expect(sut.session.hasAnyPINs == true)
    }

    // MARK: - Refresh-on-miss retry

    @Test func test_signIn_when_pin_misses_stale_cache_then_refreshes_once_and_succeeds() async throws {
        // Given an authenticator that misses on the first try (stale cache) but matches after a refresh
        let staff = makeStaff()
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResultSequence = [.failure(.invalidPIN), .success(staff)]
        let fetcher = MockPOSStaffFetcher(result: .success([]))
        let sut = makeSUT(authenticator: authenticator, fetcher: fetcher)

        // When
        try await sut.session.signIn(withPIN: "1234")

        // Then — the session refreshed the cache exactly once, then signed the staff in
        #expect(fetcher.callCount == 1)
        #expect(authenticator.authenticatedPINs == ["1234", "1234"])
        #expect(sut.session.currentStaff == staff)
        #expect(sut.session.isLocked == false)
    }

    @Test func test_signIn_when_pin_misses_and_refresh_fetch_fails_then_throws_staffFetchFailed() async {
        // Given an authenticator that always misses and a fetcher that fails the refresh
        let authenticator = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        let fetcher = MockPOSStaffFetcher(result: .failure(.transient(retryable: true)))
        let sut = makeSUT(authenticator: authenticator, fetcher: fetcher)

        // When / Then — the wrapped fetch error surfaces instead of invalidPIN
        await #expect(throws: POSAuthError.staffFetchFailed(.transient(retryable: true))) {
            try await sut.session.signIn(withPIN: "0000")
        }
        #expect(fetcher.callCount == 1)
        #expect(authenticator.authenticatedPINs == ["0000"])
    }

    @Test func test_requestManagerApproval_when_pin_misses_stale_cache_then_refreshes_once_and_succeeds() async throws {
        // Given a verify that misses on the first try but matches after a refresh
        let approver = makeStaff(userID: 45, capabilities: [POSCapability.issueRefunds.rawValue])
        let authenticator = MockPOSPINAuthenticator()
        authenticator.verifyResultSequence = [.failure(.invalidPIN), .success(approver)]
        let fetcher = MockPOSStaffFetcher(result: .success([]))
        let sut = makeSUT(authenticator: authenticator, fetcher: fetcher)

        // When
        let approvedStaff = try await sut.session.requestManagerApproval(withPIN: "9999", for: .issueRefunds)

        // Then
        #expect(fetcher.callCount == 1)
        #expect(authenticator.verifyCallCount == 2)
        #expect(approvedStaff == approver)
    }

    // MARK: - Cache-driven gating

    @Test func test_init_when_cache_is_empty_then_not_locked() {
        // Given / When an empty cache (cold start, offline, logged out)
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // Then no gating and no lock screen
        #expect(sut.session.hasAnyPINs == false)
        #expect(sut.session.isLocked == false)
    }

    @Test func test_init_when_cache_has_pins_then_locked() {
        // Given a cache already holding staff with PINs
        let cache = POSStaffCache(storage: InMemoryStaffStorage())
        cache.save([makeStaffMember(hasPIN: true)], siteID: 123)

        // When
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), cache: cache)

        // Then the session locks from the start
        #expect(sut.session.hasAnyPINs == true)
        #expect(sut.session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_fetch_returns_staff_with_pins_then_locks() async {
        // Given an empty cache (starts unlocked)
        let fetcher = MockPOSStaffFetcher(result: .success([makeStaffMember(hasPIN: true)]))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher)
        #expect(sut.session.isLocked == false)

        // When the fetch reveals PINs exist
        await sut.session.refreshPINStatus()

        // Then gating kicks in
        #expect(sut.session.hasAnyPINs == true)
        #expect(sut.session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_lock_state_changes_then_persists_it_for_cold_launch() async {
        // Given an empty cache, so the persisted key starts unlocked
        let fetcher = MockPOSStaffFetcher(result: .success([makeStaffMember(hasPIN: true)]))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)

        // When a refresh discovers PINs and the session locks
        await sut.session.refreshPINStatus()

        // Then the persisted key tracks the new lock state (read on cold launch to auto-reopen POS)
        #expect(sut.session.isLocked == true)
        #expect(sut.scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == true)
    }

    @Test func test_refreshPINStatus_when_fetch_returns_staff_without_pins_then_stays_unlocked() async {
        // Given
        let fetcher = MockPOSStaffFetcher(result: .success([makeStaffMember(hasPIN: false)]))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher)

        // When
        await sut.session.refreshPINStatus()

        // Then
        #expect(sut.session.hasAnyPINs == false)
        #expect(sut.session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_endpointUnavailable_then_clears_cache_and_unlocks() async {
        // Given a cache with PINs (locked at init)
        let cache = POSStaffCache(storage: InMemoryStaffStorage())
        cache.save([makeStaffMember(hasPIN: true)], siteID: 123)
        let fetcher = MockPOSStaffFetcher(result: .failure(.endpointUnavailable))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher, cache: cache)
        #expect(sut.session.isLocked == true)

        // When the staff route is gone (POS roles disabled server-side)
        await sut.session.refreshPINStatus()

        // Then degrade to no gating rather than locking everyone out
        #expect(sut.session.hasAnyPINs == false)
        #expect(sut.session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_fetch_fails_and_cache_empty_then_stays_unlocked() async {
        // Given an empty cache and a failing fetch (offline cold start)
        let fetcher = MockPOSStaffFetcher(result: .failure(.transient(retryable: true)))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher)
        #expect(sut.session.isLocked == false)

        // When
        await sut.session.refreshPINStatus()

        // Then no dead-end lock screen — empty cache means no gating
        #expect(sut.session.hasAnyPINs == false)
        #expect(sut.session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_cache_cleared_during_fetch_then_does_not_restore_staff() async {
        // Given a refresh in flight whose fetch would return staff with PINs
        let fetcher = MockPOSStaffFetcher(result: .success([makeStaffMember(hasPIN: true)]))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher)
        // ...but a logout (cache clear) lands while that fetch is in flight
        let session = sut.session
        fetcher.onFetchStaff = { await session.clearStaffCache() }

        // When
        await sut.session.refreshPINStatus()

        // Then the fetched staff must not be written back into the just-cleared cache
        #expect(sut.cache.load(siteID: 123) == nil)
        #expect(sut.session.hasAnyPINs == false)
        // ...and the racing logout leaves POS unlocked, not stranded behind an unsatisfiable lock screen
        #expect(sut.session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_fetch_fails_but_cache_has_pins_then_stays_locked() async {
        // Given an existing cache with PINs (locked at init) and a failing fetch (offline)
        let cache = POSStaffCache(storage: InMemoryStaffStorage())
        cache.save([makeStaffMember(hasPIN: true)], siteID: 123)
        let fetcher = MockPOSStaffFetcher(result: .failure(.transient(retryable: true)))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(), fetcher: fetcher, cache: cache)
        #expect(sut.session.isLocked == true)

        // When the refresh can't reach the server
        await sut.session.refreshPINStatus()

        // Then gating from the persisted cache is preserved — offline does not unlock
        #expect(sut.session.hasAnyPINs == true)
        #expect(sut.session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_signed_in_and_fetch_finds_pins_then_stays_unlocked() async throws {
        // Given a signed-in session
        let staff = makeStaff()
        let fetcher = MockPOSStaffFetcher(result: .success([makeStaffMember(hasPIN: true)]))
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)),
                          fetcher: fetcher)
        try await sut.session.signIn(withPIN: "1234")
        #expect(sut.session.isLocked == false)

        // When a later refresh confirms PINs exist
        await sut.session.refreshPINStatus()

        // Then the active session is not re-locked
        #expect(sut.session.isLocked == false)
        #expect(sut.session.currentStaff == staff)
    }
}

private extension DefaultPOSAccessSessionTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
        let scope: UserDefaultsTestScope
        let cache: POSStaffCache
    }

    func makeSUT(authenticator: POSPINAuthenticating,
                 fetcher: POSStaffFetching = MockPOSStaffFetcher(),
                 cache: POSStaffCache = POSStaffCache(storage: InMemoryStaffStorage()),
                 now: @escaping () -> Date = { Date() }) -> SUT {
        let scope = UserDefaultsTestScope()
        let limiter = POSLocalRateLimiter(siteID: 123, userDefaults: scope.defaults, now: now)
        let session = DefaultPOSAccessSession(
            siteID: 123,
            authenticator: authenticator,
            rateLimiter: limiter,
            cache: cache,
            fetcher: fetcher,
            userDefaults: scope.defaults
        )
        return SUT(session: session, limiter: limiter, scope: scope, cache: cache)
    }

    func makeStaffMember(userID: Int64 = 1, hasPIN: Bool) -> POSStaffMember {
        POSStaffMember(userID: userID,
                       displayName: "Staff",
                       preset: "pos_cashier",
                       capabilities: ["woocommerce_pos_process_sales": true],
                       pin: hasPIN ? .init(algorithm: "pbkdf2-sha256", iterations: 1,
                                           salt: "c2FsdA==", hash: "aGFzaA==") : nil)
    }

    func makeStaff(userID: Int64 = 1,
                   displayName: String = "Maya",
                   preset: String = "pos_manager",
                   capabilities: Set<String> = []) -> POSStaff {
        POSStaff(userID: userID,
                 displayName: displayName,
                 preset: preset,
                 capabilities: capabilities)
    }
}

@MainActor
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
