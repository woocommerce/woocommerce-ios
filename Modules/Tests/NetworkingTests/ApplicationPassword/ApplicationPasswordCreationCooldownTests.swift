import Testing
import Foundation
import enum Alamofire.AFError
@testable import NetworkingCore

@Suite("ApplicationPasswordCreationCooldown")
struct ApplicationPasswordCreationCooldownTests: Sendable {

    @Test func test_pausedFailure_when_ordinary_failures_repeat_then_pause_doubles_up_to_one_hour() {
        // Given
        var sut = ApplicationPasswordCreationCooldown()
        let error = URLError(.cannotFindHost)
        var failedAt = ContinuousClock.now
        let pauses: [Duration] = [
            .seconds(10), .seconds(20), .seconds(40), .seconds(80), .seconds(160), .seconds(320),
            .seconds(640), .seconds(1280), .seconds(2560), .seconds(3600), .seconds(3600)
        ]
        var outcomes = [(Bool, Bool)]()

        // When
        for pause in pauses {
            sut.recordFailure(error, at: failedAt)
            let isPausedBeforeEnd = sut.pausedFailure(at: failedAt + pause - .milliseconds(1)) != nil
            let isPausedAtEnd = sut.pausedFailure(at: failedAt + pause) != nil
            outcomes.append((isPausedBeforeEnd, isPausedAtEnd))
            failedAt = failedAt + pause
        }

        // Then
        for (index, outcome) in outcomes.enumerated() {
            #expect(outcome.0 && !outcome.1,
                    "Cooldown step \(index + 1) should last exactly \(pauses[index]).")
        }
    }

    @Test(arguments: ApplicationPasswordConnectionFailure.allCases)
    func test_pausedFailure_when_creation_fails_with_connection_failure_then_pauses_ten_seconds(
        _ failure: ApplicationPasswordConnectionFailure
    ) {
        // Given
        var sut = ApplicationPasswordCreationCooldown()
        let error = failure.error
        let firstFailure = ContinuousClock.now

        // When
        sut.recordFailure(error, at: firstFailure)
        let isPausedBeforeFirstEnd = sut.pausedFailure(at: firstFailure + .seconds(10) - .milliseconds(1)) != nil
        let isPausedAtFirstEnd = sut.pausedFailure(at: firstFailure + .seconds(10)) != nil
        let secondFailure = firstFailure + .seconds(10)
        sut.recordFailure(error, at: secondFailure)
        let isPausedBeforeSecondEnd = sut.pausedFailure(at: secondFailure + .seconds(10) - .milliseconds(1)) != nil
        let isPausedAtSecondEnd = sut.pausedFailure(at: secondFailure + .seconds(10)) != nil

        // Then
        #expect(isPausedBeforeFirstEnd, "\(failure.rawValue): first pause should remain active before 10 seconds.")
        #expect(!isPausedAtFirstEnd, "\(failure.rawValue): first pause should end at 10 seconds.")
        #expect(isPausedBeforeSecondEnd, "\(failure.rawValue): second pause should remain active before 10 seconds.")
        #expect(!isPausedAtSecondEnd, "\(failure.rawValue): second pause should end at 10 seconds.")
    }

    @Test func test_pausedFailure_when_ordinary_failure_follows_connection_failure_then_pauses_twenty_seconds() {
        // Given
        var sut = ApplicationPasswordCreationCooldown()
        let failedAt = ContinuousClock.now
        sut.recordFailure(URLError(.timedOut), at: failedAt)

        // When
        let ordinaryFailureAt = failedAt + .seconds(10)
        sut.recordFailure(URLError(.cannotFindHost), at: ordinaryFailureAt)

        // Then
        #expect(sut.pausedFailure(at: ordinaryFailureAt + .seconds(20) - .milliseconds(1)) != nil,
                "An ordinary failure after a connection failure should double the pause to 20 seconds.")
        #expect(sut.pausedFailure(at: ordinaryFailureAt + .seconds(20)) == nil,
                "The 20-second pause should end on schedule.")
    }

    @Test func test_reset_when_cooldown_is_running_then_ends_pause_and_restarts_growth() {
        // Given
        var sut = ApplicationPasswordCreationCooldown()
        let firstFailureAt = ContinuousClock.now
        let secondFailureAt = firstFailureAt + .seconds(10)
        let resetAt = secondFailureAt + .seconds(1)
        let error = URLError(.cannotFindHost)
        sut.recordFailure(error, at: firstFailureAt)
        sut.recordFailure(error, at: secondFailureAt)

        // When
        sut.reset()
        let isPausedAfterReset = sut.pausedFailure(at: resetAt) != nil
        sut.recordFailure(error, at: resetAt)

        // Then
        #expect(!isPausedAfterReset, "Reset should clear the active cooldown.")
        #expect(sut.pausedFailure(at: resetAt + .seconds(10) - .milliseconds(1)) != nil,
                "A failure after reset should start a fresh 10-second pause.")
        #expect(sut.pausedFailure(at: resetAt + .seconds(10)) == nil,
                "The fresh 10-second pause should end on schedule.")
    }
}

enum ApplicationPasswordConnectionFailure: String, CaseIterable, Sendable {
    case notConnectedToInternet
    case wrappedNotConnectedToInternet
    case networkConnectionLost
    case wrappedNetworkConnectionLost
    case timedOut
    case wrappedTimedOut

    var error: Error {
        switch self {
        case .notConnectedToInternet:
            return URLError(.notConnectedToInternet)
        case .wrappedNotConnectedToInternet:
            return AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet))
        case .networkConnectionLost:
            return URLError(.networkConnectionLost)
        case .wrappedNetworkConnectionLost:
            return AFError.sessionTaskFailed(error: URLError(.networkConnectionLost))
        case .timedOut:
            return URLError(.timedOut)
        case .wrappedTimedOut:
            return AFError.sessionTaskFailed(error: URLError(.timedOut))
        }
    }
}
