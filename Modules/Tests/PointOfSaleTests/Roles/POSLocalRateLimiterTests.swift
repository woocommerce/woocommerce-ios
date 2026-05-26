import Foundation
import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct POSLocalRateLimiterTests {
    @Test func test_checkAllowed_when_fresh_state_then_does_not_throw() throws {
        // Given
        let sut = makeSUT()

        // When / Then
        try sut.limiter.checkAllowed()
    }

    @Test func test_checkAllowed_after_5_failures_then_throws_rateLimited_30_seconds_out() throws {
        // Given
        var nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let sut = makeSUT(now: { nowValue })

        // When
        for _ in 0..<5 {
            sut.limiter.recordFailure()
        }

        // Then
        do {
            try sut.limiter.checkAllowed()
            Issue.record("Expected rateLimited error")
        } catch POSAuthError.rateLimited(let until) {
            #expect(until == nowValue.addingTimeInterval(30))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func test_checkAllowed_after_10_failures_then_throws_rateLimited_5_minutes_out() throws {
        // Given
        let nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let sut = makeSUT(now: { nowValue })

        // When
        for _ in 0..<10 {
            sut.limiter.recordFailure()
        }

        // Then
        do {
            try sut.limiter.checkAllowed()
            Issue.record("Expected rateLimited error")
        } catch POSAuthError.rateLimited(let until) {
            #expect(until == nowValue.addingTimeInterval(300))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func test_checkAllowed_after_15_failures_then_throws_permanentlyLocked() throws {
        // Given
        let sut = makeSUT()

        // When
        for _ in 0..<15 {
            sut.limiter.recordFailure()
        }

        // Then
        #expect(throws: POSAuthError.permanentlyLocked) {
            try sut.limiter.checkAllowed()
        }
    }

    @Test func test_checkAllowed_when_lockout_expired_then_does_not_throw() throws {
        // Given
        var nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let sut = makeSUT(now: { nowValue })
        for _ in 0..<5 {
            sut.limiter.recordFailure()
        }

        // When
        nowValue = nowValue.addingTimeInterval(31)

        // Then
        try sut.limiter.checkAllowed()
    }

    @Test func test_checkAllowed_when_permanently_locked_then_keeps_throwing_after_clock_advance() throws {
        // Given
        var nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let sut = makeSUT(now: { nowValue })
        for _ in 0..<15 {
            sut.limiter.recordFailure()
        }

        // When
        nowValue = nowValue.addingTimeInterval(10_000)

        // Then
        #expect(throws: POSAuthError.permanentlyLocked) {
            try sut.limiter.checkAllowed()
        }
    }

    @Test func test_reset_when_called_then_clears_failures_and_lockout_and_permanent() throws {
        // Given
        let sut = makeSUT()
        for _ in 0..<15 {
            sut.limiter.recordFailure()
        }

        // When
        sut.limiter.reset()

        // Then
        try sut.limiter.checkAllowed()
    }

    @Test func test_errorForCurrentState_when_below_threshold_then_returns_fallback() {
        // Given
        let sut = makeSUT()
        sut.limiter.recordFailure()

        // When
        let error = sut.limiter.errorForCurrentState(fallback: .invalidPIN)

        // Then
        #expect(error == .invalidPIN)
    }

    @Test func test_errorForCurrentState_when_at_30_second_threshold_then_returns_rateLimited() {
        // Given
        let nowValue = Date(timeIntervalSinceReferenceDate: 1000)
        let sut = makeSUT(now: { nowValue })
        for _ in 0..<5 {
            sut.limiter.recordFailure()
        }

        // When
        let error = sut.limiter.errorForCurrentState(fallback: .invalidPIN)

        // Then
        #expect(error == .rateLimited(until: nowValue.addingTimeInterval(30)))
    }

    @Test func test_errorForCurrentState_when_at_permanent_threshold_then_returns_permanentlyLocked() {
        // Given
        let sut = makeSUT()
        for _ in 0..<15 {
            sut.limiter.recordFailure()
        }

        // When
        let error = sut.limiter.errorForCurrentState(fallback: .invalidPIN)

        // Then
        #expect(error == .permanentlyLocked)
    }

    @Test func test_state_when_new_limiter_uses_same_defaults_then_persists() throws {
        // Given
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstLimiter = POSLocalRateLimiter(siteID: 123, userDefaults: defaults, now: { Date(timeIntervalSinceReferenceDate: 1000) })
        for _ in 0..<5 {
            firstLimiter.recordFailure()
        }

        // When
        let secondLimiter = POSLocalRateLimiter(siteID: 123, userDefaults: defaults, now: { Date(timeIntervalSinceReferenceDate: 1000) })

        // Then
        #expect(throws: POSAuthError.self) {
            try secondLimiter.checkAllowed()
        }
    }

    @Test func test_state_when_different_sites_then_independent() throws {
        // Given
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let siteA = POSLocalRateLimiter(siteID: 111, userDefaults: defaults, now: { Date(timeIntervalSinceReferenceDate: 1000) })
        let siteB = POSLocalRateLimiter(siteID: 222, userDefaults: defaults, now: { Date(timeIntervalSinceReferenceDate: 1000) })

        // When
        for _ in 0..<5 {
            siteA.recordFailure()
        }

        // Then
        #expect(throws: POSAuthError.self) {
            try siteA.checkAllowed()
        }
        try siteB.checkAllowed()
    }
}

private extension POSLocalRateLimiterTests {
    struct SUT {
        let limiter: POSLocalRateLimiter
        let defaults: UserDefaults
        let suiteName: String
    }

    func makeSUT(siteID: Int64 = 123, now: @escaping () -> Date = { Date() }) -> SUT {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let limiter = POSLocalRateLimiter(siteID: siteID, userDefaults: defaults, now: now)
        return SUT(limiter: limiter, defaults: defaults, suiteName: suiteName)
    }
}
