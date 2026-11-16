import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLocalRateLimiterTests {
    private let storage = InMemoryPOSSecureStorage()
    private let clock = MockPOSPINClock()

    @Test func test_failures_when_thresholds_are_reached_then_only_each_fifth_guess_starts_the_escalating_wait() async throws {
        // Given
        let limiter = makeLimiter()
        let token = limiter.sessionTokens.invalidate()
        let wrong = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))

        // When / Then
        for attempt in 1...30 {
            let wait = attempt.isMultiple(of: 5) ? duration(at: attempt) : 0
            let expected: POSAuthError = wait > 0 ? .rateLimited(remainingSeconds: wait) : .invalidPIN
            await #expect(throws: expected) {
                try await limiter.authenticate(pin: "0000", using: wrong, token: token)
            }
            if wait > 0 {
                await #expect(throws: POSAuthError.rateLimited(remainingSeconds: wait)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
                clock.seconds += Double(wait)
                try await limiter.checkAllowed(token: limiter.sessionTokens.current())
            }
        }
    }

    @Test func test_wait_when_service_is_recreated_after_saving_elapsed_time_then_preserves_remaining_wait_and_credits_zero_unknown_gap() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(5, using: limiter)
        clock.seconds += 12
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 18)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
        await limiter.saveElapsedTime(token: limiter.sessionTokens.current())

        // When
        clock.seconds += 100000
        for _ in 0..<3 {
            let recreated = makeLimiter()
            // Then
            await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 18)) { try await recreated.checkAllowed(token: recreated.sessionTokens.current()) }
        }
    }

    @Test func test_clock_when_same_service_regresses_then_never_credits_the_recovered_interval_twice() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(5, using: limiter)
        clock.seconds += 10
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 20)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }

        // When
        clock.seconds -= 20
        await #expect(throws: POSAuthError.unknown) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
        clock.seconds += 20

        // Then
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 20)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
        clock.seconds += 1
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 19)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
    }

    @Test func test_quiet_reset_when_24_hours_pass_without_wrong_pin_then_starts_a_fresh_budget() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        clock.seconds += 86399
        await fail(1, using: limiter)

        // When
        clock.seconds += 86399
        try await limiter.checkAllowed(token: limiter.sessionTokens.current())
        #expect(try failures() == 5)
        clock.seconds += 1
        try await limiter.checkAllowed(token: limiter.sessionTokens.current())

        // Then
        #expect(try failures() == 0)
        await fail(1, using: limiter)
        #expect(try failures() == 1)
    }

    @Test func test_cashier_success_when_budget_exists_then_preserves_previous_failures_and_quiet_anchor() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        clock.seconds += 60

        // When
        _ = try await limiter.authenticate(pin: "5678", using: MockPOSPINAuthenticator(authenticateResult: .success(POSLocalRole.cashier.staff)),
                                           token: limiter.sessionTokens.invalidate())

        // Then
        #expect(try failures() == 4)
        #expect(try record()["quiet"] == 60)
        await fail(1, using: limiter)
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
    }

    @Test func test_admin_success_when_credential_has_settings_capability_then_resets_budget_regardless_of_display_name() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        let staff = POSStaff(displayName: "Cashier", capabilities: [.manageStoreSettings])

        // When
        _ = try await limiter.authenticate(pin: "1234", using: MockPOSPINAuthenticator(authenticateResult: .success(staff)),
                                           token: limiter.sessionTokens.invalidate())

        // Then
        #expect(try failures() == 0)
    }

    @Test func test_approval_when_cashier_lacks_requested_capability_then_counts_towards_unlock_wait() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)

        // When / Then
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) {
            try await limiter.authenticate(pin: "5678", using: MockPOSPINAuthenticator(authenticateResult: .success(POSLocalRole.cashier.staff)),
                                           capability: .issueRefunds, token: limiter.sessionTokens.invalidate())
        }
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
    }

    @Test func test_auth_failure_when_source_is_unavailable_then_preserves_budget() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        let before = try record()

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "0000", using: MockPOSPINAuthenticator(authenticateResult: .failure(.unknown)),
                                           token: limiter.sessionTokens.invalidate())
        }
        #expect(try record() == before)
    }

    @Test(arguments: [true, false]) func test_storage_failure_when_read_or_write_fails_then_authenticator_is_not_called(readFailure: Bool) async {
        // Given
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()
        storage.shouldFail = readFailure
        storage.shouldFailWrites = !readFailure

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        }
        #expect(authenticator.authenticatedPINs.isEmpty)
    }

    @Test(arguments: [Double.nan, -Double.infinity, Double(-1)])
    func test_clock_when_unusable_then_fails_closed_without_authentication(seconds: Double) async {
        // Given
        clock.seconds = seconds
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        }
        #expect(authenticator.authenticatedPINs.isEmpty)
        #expect(storage.values.isEmpty)
    }

    @Test(arguments: [
        Data([0]),
        Data(#"{"failures":3,"wait":0"#.utf8),
        Data(#"{"failures":-1,"wait":0,"quiet":0}"#.utf8),
        Data(#"{"failures":5,"wait":-1,"quiet":0}"#.utf8),
        Data(#"{"failures":5,"wait":3601,"quiet":0}"#.utf8),
        Data(#"{"failures":5,"wait":0,"quiet":86401}"#.utf8),
        Data(#"{"attempts":5}"#.utf8),
        Data(#"{"failures":"5","wait":0,"quiet":0}"#.utf8)
    ])
    func test_corrupt_state_when_record_is_malformed_then_stays_unavailable_without_changing_it(data: Data) async throws {
        // Given
        try storage.setData(data, forKey: "attempts.123")
        let writes = storage.writeCount
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()
        let token = limiter.sessionTokens.invalidate()

        // When / Then
        await #expect(throws: POSAuthError.unknown) { try await limiter.checkAllowed(token: token) }
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: token)
        }
        #expect(authenticator.authenticatedPINs.isEmpty)
        #expect(storage.values["attempts.123"] == data)
        #expect(storage.writeCount == writes)
    }

    @Test func test_storage_write_failure_when_record_exists_then_stays_blocked_without_erasing_it() async throws {
        // Given
        let existing = Data(#"{"failures":3,"wait":0,"quiet":0}"#.utf8)
        try storage.setData(existing, forKey: "attempts.123")
        storage.shouldFailWrites = true
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()
        let token = limiter.sessionTokens.invalidate()

        // When / Then
        for _ in 0..<2 {
            await #expect(throws: POSAuthError.unknown) {
                try await limiter.authenticate(pin: "1234", using: authenticator, token: token)
            }
        }
        #expect(authenticator.authenticatedPINs.isEmpty)
        #expect(storage.values["attempts.123"] == existing)
    }

    @Test func test_corrupt_state_when_storage_read_fails_then_stays_unavailable() async throws {
        // Given
        try storage.setData(Data([0]), forKey: "attempts.123")
        storage.shouldFail = true
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        }
        #expect(authenticator.authenticatedPINs.isEmpty)
        storage.shouldFail = false
        #expect(storage.values["attempts.123"] == Data([0]))
    }

    @Test func test_budget_when_sites_differ_then_is_independent() async throws {
        // Given
        await fail(5, using: makeLimiter())

        // When / Then
        let other = makeLimiter(siteID: 456)
        try await other.checkAllowed(token: other.sessionTokens.current())
        let original = makeLimiter()
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) { try await original.checkAllowed(token: original.sessionTokens.current()) }
    }
    @Test func test_precharge_when_authentication_is_pending_then_recreation_observes_the_failed_guess() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        let authenticator = MockPOSPINAuthenticator()
        authenticator.onAuthenticate = {
            // Then: the durable charge exists before a comparison result is returned.
            #expect((try? failures()) == 5)
            let recreated = makeLimiter()
            await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 30)) { try await recreated.checkAllowed(token: recreated.sessionTokens.current()) }
        }

        // When
        _ = try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        #expect(try failures() == 0)
    }

    @Test func test_concurrent_approval_when_unlock_is_pending_then_does_not_compare_or_overwrite_budget() async throws {
        // Given
        let limiter = makeLimiter()
        let token = limiter.sessionTokens.invalidate()
        let first = MockPOSPINAuthenticator()
        let second = MockPOSPINAuthenticator()
        first.onAuthenticate = {
            // When / Then
            await #expect(throws: POSAuthError.unknown) {
                try await limiter.authenticate(pin: "1234", using: second, capability: .issueRefunds, token: token)
            }
            #expect(second.authenticatedPINs.isEmpty)
            #expect((try? failures()) == 1)
        }

        _ = try await limiter.authenticate(pin: "1234", using: first, token: token)
        #expect(try failures() == 0)
    }

    @Test func test_success_when_durable_reset_fails_then_keeps_charge_and_denies_unlock() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        let authenticator = MockPOSPINAuthenticator()
        authenticator.onAuthenticate = { storage.shouldFailWrites = true }

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        }
        #expect(try failures() == 5)
    }

    @Test func test_session_tokens_when_storage_was_cleared_by_logout_then_stay_invalid_and_retire_the_limiter() throws {
        // Given
        let limiter = makeLimiter()
        let old = limiter.sessionTokens.current()

        // When
        try storage.removeAll()

        // Then
        #expect(limiter.sessionTokens.invalidate(ifCurrent: old) == nil)
        #expect(limiter.sessionTokens.isCurrent(limiter.sessionTokens.invalidate()) == false)
        #expect(limiter.isRetired)
        let replacement = POSLocalRateLimiter(siteID: 123, storage: storage.reopened(), clock: clock)
        #expect(replacement.isRetired == false)
        #expect(replacement.sessionTokens.isCurrent(replacement.sessionTokens.current()))
    }

    @Test func test_logout_when_authentication_is_pending_then_cannot_restore_or_reset_cleared_state() async throws {
        // Given
        let limiter = makeLimiter()
        let authenticator = MockPOSPINAuthenticator()
        authenticator.onAuthenticate = {
            try? storage.removeAll()
        }

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.invalidate())
        }
        #expect(storage.values.isEmpty)
    }

    @Test func test_countdown_when_polled_each_second_then_uses_cache_and_saves_only_when_the_wait_ends() async {
        // Given
        let limiter = makeLimiter()
        await fail(5, using: limiter)
        let reads = storage.readCount
        let writes = storage.writeCount

        // When
        for _ in 0..<4 {
            clock.seconds += 1
            _ = try? await limiter.checkAllowed(token: limiter.sessionTokens.current())
        }

        // Then
        #expect(storage.readCount == reads)
        #expect(storage.writeCount == writes)
        clock.seconds += 1
        await #expect(throws: POSAuthError.rateLimited(remainingSeconds: 25)) { try await limiter.checkAllowed(token: limiter.sessionTokens.current()) }
        #expect(storage.writeCount == writes)
        clock.seconds += 25
        try? await limiter.checkAllowed(token: limiter.sessionTokens.current())
        #expect(storage.writeCount == writes + 1)
    }

    @Test func test_quiet_progress_when_service_restarts_then_retains_saved_credit_without_crediting_the_gap() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(1, using: limiter)
        clock.seconds += 43200
        await limiter.saveElapsedTime(token: limiter.sessionTokens.current())
        #expect(try record()["quiet"] == 43200)

        // When
        clock.seconds += 1000000
        let recreated = makeLimiter()
        try await recreated.checkAllowed(token: recreated.sessionTokens.current())

        // Then
        #expect(try failures() == 1)
        clock.seconds += 43199
        await recreated.saveElapsedTime(token: recreated.sessionTokens.current())
        #expect(try failures() == 1)
        clock.seconds += 1
        try await recreated.checkAllowed(token: recreated.sessionTokens.current())
        #expect(try failures() == 0)
    }

    @Test func test_cancellation_when_comparison_returns_then_preserves_precharge_and_never_resets_budget() async throws {
        // Given
        let limiter = makeLimiter()
        await fail(4, using: limiter)
        let authenticator = MockPOSPINAuthenticator()
        authenticator.onAuthenticate = { withUnsafeCurrentTask { $0?.cancel() } }

        // When
        let task = Task { try await limiter.authenticate(pin: "1234", using: authenticator, token: limiter.sessionTokens.current()) }
        let result = await task.result

        // Then
        #expect(throws: POSAuthError.unknown) { try result.get() }
        #expect(try failures() == 5)
    }
}

private extension POSLocalRateLimiterTests {
    func makeLimiter(siteID: Int64 = 123) -> POSLocalRateLimiter { POSLocalRateLimiter(siteID: siteID, storage: storage, clock: clock) }

    func fail(_ count: Int, using limiter: POSLocalRateLimiter) async {
        let token = limiter.sessionTokens.invalidate()
        let wrong = MockPOSPINAuthenticator(authenticateResult: .failure(.invalidPIN))
        for _ in 0..<count { _ = try? await limiter.authenticate(pin: "0000", using: wrong, token: token) }
    }

    func failures() throws -> Int { Int(try record()["failures"] ?? -1) }
    func record() throws -> [String: Double] { try decoded(storage.values["attempts.123"]) }
    func decoded(_ data: Data?) throws -> [String: Double] { try JSONDecoder().decode([String: Double].self, from: #require(data)) }
    func duration(at count: Int) -> Int {
        switch count { case 5: 30; case 10: 300; case 15: 1800; default: 3600 }
    }
}
