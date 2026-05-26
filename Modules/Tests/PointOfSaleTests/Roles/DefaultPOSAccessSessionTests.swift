import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSAccessSessionTests {
    @Test func test_signIn_when_pin_is_valid_then_sets_currentStaff_and_unlocks_and_resets_limiter() async throws {
        // Given
        let staff = POSStaff(
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
        let staff = POSStaff(displayName: "Maya", role: "shop_manager", capabilities: [])
        let sut = makeSUT(authenticator: MockPOSPINAuthenticator(authenticateResult: .success(staff)))
        try await sut.session.signIn(withPIN: "1234")

        // When
        sut.session.lock()

        // Then
        #expect(sut.session.isLocked == true)
        #expect(sut.session.currentStaff == staff)
    }

    @Test func test_refreshPINStatus_when_authenticator_succeeds_then_updates_hasAnyPINs() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(hasAnyPINsResult: .success(true))
        let sut = makeSUT(authenticator: authenticator)

        // When
        await sut.session.refreshPINStatus()

        // Then
        #expect(sut.session.hasAnyPINs == true)
        #expect(authenticator.hasAnyPINsCallCount == 1)
    }

    @Test func test_refreshPINStatus_when_authenticator_fails_then_keeps_last_value() async {
        // Given
        let authenticator = MockPOSPINAuthenticator(hasAnyPINsResult: .success(true))
        let sut = makeSUT(authenticator: authenticator)
        await sut.session.refreshPINStatus()

        // When
        authenticator.hasAnyPINsResult = .failure(.unknown)
        await sut.session.refreshPINStatus()

        // Then
        #expect(sut.session.hasAnyPINs == true)
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
        let staff = POSStaff(displayName: "Maya", role: "pos_cashier", capabilities: [])
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
}

private extension DefaultPOSAccessSessionTests {
    struct SUT {
        let session: DefaultPOSAccessSession
        let limiter: POSLocalRateLimiter
    }

    func makeSUT(authenticator: POSPINAuthenticating,
                 now: @escaping () -> Date = { Date() }) -> SUT {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let limiter = POSLocalRateLimiter(siteID: 123, userDefaults: defaults, now: now)
        let session = DefaultPOSAccessSession(authenticator: authenticator, rateLimiter: limiter)
        return SUT(session: session, limiter: limiter)
    }
}
