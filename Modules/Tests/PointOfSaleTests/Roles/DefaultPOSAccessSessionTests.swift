import Foundation
import Testing
import struct Networking.POSStaffMember
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSAccessSessionTests {
    @Test func test_signIn_when_pin_is_valid_then_sets_currentStaff_and_unlocks_and_resets_limiter() async throws {
        // Given
        let staff = POSStaff(
            userID: 1,
            userLogin: "maya",
            displayName: "Maya",
            role: "shop_manager",
            capabilities: Set(POSCapability.allCases.map(\.rawValue))
        )
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
        let staff = POSStaff(userID: 1, userLogin: "maya", displayName: "Maya", role: "shop_manager", capabilities: [])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When
        sut.session.lock()

        // Then
        #expect(sut.session.isLocked == true)
        #expect(sut.session.currentStaff == staff)
    }

    @Test func test_refreshPINStatus_when_fetch_succeeds_then_caches_and_sets_pinStatus_present() async {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        let member = POSStaffMember(userID: 1, userLogin: "u1", displayName: "U1",
                                    role: "pos_cashier", capabilities: ["view_pos": true],
                                    pin: .init(algo: "pbkdf2-sha256", iterations: 10000,
                                               salt: "c2FsdA==", hash: "aGFzaA=="))
        let session = makeSession(cache: cache, fetcher: MockPOSStaffFetcher(staff: [member]), siteID: 1)

        // When
        await session.refreshPINStatus()

        // Then
        #expect(session.pinStatus == .present)
        #expect(cache.load(siteID: 1)?.count == 1)
    }

    @Test func test_initial_state_when_session_created_then_pinStatus_is_unknown_and_locked() {
        // Given / When
        let session = makeSession()

        // Then
        #expect(session.pinStatus == .unknown)
        #expect(session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_TTL_not_expired_then_skips_fetch() async {
        // Given
        let now = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { now })
        cache.save([], siteID: 1)
        let fetcher = MockPOSStaffFetcher(staff: [])
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { now.addingTimeInterval(5) })

        // When
        await session.refreshPINStatus()

        // Then
        #expect(fetcher.calls == 0)
    }

    @Test func test_refreshPINStatus_when_TTL_path_finds_no_pins_then_unlocks_session() async {
        // Given - cache has zero PINs and is within the TTL window
        let now = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { now })
        cache.save([], siteID: 1)
        let fetcher = MockPOSStaffFetcher(staff: [])
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { now.addingTimeInterval(5) })

        // When - refresh hits the TTL early-return path
        await session.refreshPINStatus()

        // Then - session is unlocked even though the fetcher never fired
        #expect(fetcher.calls == 0)
        #expect(session.pinStatus == .absent)
        #expect(session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_TTL_expired_then_refetches() async {
        // Given
        let saveTime = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { saveTime })
        cache.save([], siteID: 1)
        let fetcher = MockPOSStaffFetcher(staff: [])
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { saveTime.addingTimeInterval(31) })

        // When
        await session.refreshPINStatus()

        // Then
        #expect(fetcher.calls == 1)
    }

    @Test func test_refreshPINStatus_when_flag_disabled_server_side_then_clears_cache_and_unlocks() async {
        // Given
        let saveTime = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { saveTime })
        cache.save([makeMember(id: 1, hasPIN: true)], siteID: 1)
        let fetcher = MockPOSStaffFetcher(error: .flagDisabledServerSide)
        // Session clock is past TTL so the fetch is not skipped.
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { saveTime.addingTimeInterval(31) })

        // When
        await session.refreshPINStatus()

        // Then
        #expect(cache.load(siteID: 1) == nil)
        #expect(session.flagDisabledServerSide == true)
        #expect(session.pinStatus == .absent)
        #expect(session.isLocked == false)
    }

    @Test func test_refreshPINStatus_when_transient_error_with_cache_then_keeps_existing_cache_state() async {
        // Given
        let saveTime = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { saveTime })
        let existing = [makeMember(id: 1, hasPIN: true)]
        cache.save(existing, siteID: 1)
        let fetcher = MockPOSStaffFetcher(error: .transient(retryable: true))
        // Session clock is past TTL so the fetch is not skipped.
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { saveTime.addingTimeInterval(31) })

        // When
        await session.refreshPINStatus()

        // Then
        #expect(cache.load(siteID: 1) == existing)
        #expect(session.pinStatus == .present)
    }

    // MARK: - Cold-cache + refresh-failure cases (P1 regression coverage)

    @Test func test_refreshPINStatus_when_cold_cache_and_transient_error_then_stays_unknown_and_locked() async {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        let fetcher = MockPOSStaffFetcher(error: .transient(retryable: true))
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1)

        // When
        await session.refreshPINStatus()

        // Then
        #expect(session.pinStatus == .unknown)
        #expect(session.isLocked == true)
        #expect(cache.lastFetched(siteID: 1) == nil)
    }

    @Test func test_refreshPINStatus_when_cold_cache_and_admin_missing_capability_then_stays_unknown_and_locked() async {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        let fetcher = MockPOSStaffFetcher(error: .adminMissingCapability)
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1)

        // When
        await session.refreshPINStatus()

        // Then
        #expect(session.pinStatus == .unknown)
        #expect(session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_cold_cache_and_malformed_response_then_stays_unknown_and_locked() async {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        let fetcher = MockPOSStaffFetcher(error: .malformedResponse)
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1)

        // When
        await session.refreshPINStatus()

        // Then
        #expect(session.pinStatus == .unknown)
        #expect(session.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_cache_payload_missing_then_does_not_unlock_via_torn_cache() async {
        // Given - torn cache: timestamp valid + within TTL, but staff payload gone.
        // Without atomicity, the TTL early-return would call applyCachedPINStatus,
        // see hasAnyPINs == false (because load() returns nil), and unlock POS.
        let storage = InMemoryKeyValueStorage()
        let now = Date()
        let cache = POSStaffCache(storage: storage, now: { now })
        cache.save([makeMember(id: 1, hasPIN: true)], siteID: 1)
        storage.setString(nil, forKey: "staff.1")
        let fetcher = MockPOSStaffFetcher(error: .transient(retryable: true))
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { now.addingTimeInterval(5) })

        // When
        await session.refreshPINStatus()

        // Then - the missing payload made lastFetched return nil, so the TTL early-return
        // was skipped, a real fetch was attempted, it failed, and the session stays gated.
        #expect(fetcher.calls == 1)
        #expect(session.pinStatus == .unknown)
        #expect(session.isLocked == true)
    }

    @Test func test_requestManagerApproval_when_called_then_throws_unknown() async {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await sut.session.requestManagerApproval(withPIN: "1234", for: .refundShopOrders)
        }
    }

    @Test func test_allows_when_currentStaff_has_capability_then_returns_true() async throws {
        // Given
        let staff = POSStaff(
            userID: 1,
            userLogin: "maya",
            displayName: "Maya",
            role: "shop_manager",
            capabilities: [POSCapability.refundShopOrders.rawValue]
        )
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.refundShopOrders) == true)
    }

    @Test func test_allows_when_currentStaff_lacks_capability_then_returns_false() async throws {
        // Given
        let staff = POSStaff(userID: 1, userLogin: "maya", displayName: "Maya", role: "pos_cashier", capabilities: [])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When / Then
        #expect(sut.session.allows(.refundShopOrders) == false)
    }

    @Test func test_allows_when_no_currentStaff_then_returns_false() {
        // Given
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator())

        // When / Then
        #expect(sut.session.allows(.refundShopOrders) == false)
    }

    @Test func test_clearStaffCache_resets_state_to_unknown_and_locked() async {
        // Given - prior successful refresh leaves cache populated and flag flipped
        let saveTime = Date()
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { saveTime })
        cache.save([makeMember(id: 1, hasPIN: true)], siteID: 1)
        let fetcher = MockPOSStaffFetcher(error: .flagDisabledServerSide)
        let session = makeSession(cache: cache, fetcher: fetcher, siteID: 1,
                                  now: { saveTime.addingTimeInterval(31) })
        await session.refreshPINStatus()
        #expect(session.flagDisabledServerSide == true)

        // When
        session.clearStaffCache()

        // Then
        #expect(cache.load(siteID: 1) == nil)
        #expect(session.pinStatus == .unknown)
        #expect(session.currentStaff == nil)
        #expect(session.isLocked == true)
        #expect(session.flagDisabledServerSide == false)
    }

    @Test func test_refreshPINStatus_when_fetch_returns_no_pins_then_unlocks_session() async {
        // Given - admin removed all PINs
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        let memberWithoutPIN = POSStaffMember(userID: 1, userLogin: "u1", displayName: "U1",
                                              role: "pos_cashier", capabilities: ["view_pos": true],
                                              pin: nil)
        let session = makeSession(cache: cache,
                                  fetcher: MockPOSStaffFetcher(staff: [memberWithoutPIN]),
                                  siteID: 1)

        // When
        await session.refreshPINStatus()

        // Then
        #expect(session.pinStatus == .absent)
        #expect(session.isLocked == false)
    }
}

private extension DefaultPOSAccessSessionTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
        let scope: UserDefaultsTestScope
    }

    func makeSUT(authenticator: POSPINAuthenticating,
                 now: @escaping () -> Date = { Date() }) -> SUT {
        let scope = UserDefaultsTestScope()
        let limiter = POSLocalRateLimiter(siteID: 123, userDefaults: scope.defaults, now: now)
        let session = makeSession(authenticator: authenticator, rateLimiter: limiter, now: now)
        return SUT(session: session, limiter: limiter, scope: scope)
    }

    func makeSession(authenticator: POSPINAuthenticating? = nil,
                     rateLimiter: POSLocalRateLimiter? = nil,
                     cache: POSStaffCache = POSStaffCache(storage: InMemoryKeyValueStorage()),
                     fetcher: POSStaffFetching = MockPOSStaffFetcher(staff: []),
                     siteID: Int64 = 1,
                     now: @escaping @Sendable () -> Date = Date.init) -> DefaultPOSAccessSession {
        let resolvedAuthenticator = authenticator ?? MockPOSPINAuthenticator()
        let limiter = rateLimiter ?? POSLocalRateLimiter(siteID: siteID)
        return DefaultPOSAccessSession(authenticator: resolvedAuthenticator,
                                       rateLimiter: limiter,
                                       cache: cache,
                                       fetcher: fetcher,
                                       siteID: siteID,
                                       now: now)
    }

    func makeMember(id: Int64, hasPIN: Bool) -> POSStaffMember {
        let pin: POSStaffMember.PINDetails? = hasPIN
            ? .init(algo: "pbkdf2-sha256", iterations: 10000, salt: "c2FsdA==", hash: "aGFzaA==")
            : nil
        return POSStaffMember(userID: id, userLogin: "u\(id)", displayName: "U\(id)",
                              role: "pos_cashier", capabilities: ["view_pos": true], pin: pin)
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
