import Testing
import Foundation
import Observation
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct POSTapToPayAvailabilityControllerTests {

    // MARK: - Initial State

    @Test func init_then_state_is_unknown() {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        // Checker never completes during synchronous init inspection

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Then
        #expect(sut.state == .unknown)
    }

    // MARK: - State Resolved to Available

    @Test func checkAvailability_when_checker_returns_available_then_state_transitions_to_available() async {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        checker.resultToReturn = .available

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Then – wait for the background Task in init to resolve the state
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.state
            } onChange: {
                Task { @MainActor in
                    if case .available = sut.state {
                        continuation.resume()
                    }
                }
            }
        }

        #expect(sut.state == .available)
    }

    // MARK: - State Resolved to Unavailable

    @Test func checkAvailability_when_checker_returns_featureFlagDisabled_then_state_transitions_to_unavailable_featureFlagDisabled() async {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        checker.resultToReturn = .unavailable(reason: .featureFlagDisabled)

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Then
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.state
            } onChange: {
                Task { @MainActor in
                    if case .unavailable = sut.state {
                        continuation.resume()
                    }
                }
            }
        }

        #expect(sut.state == .unavailable(reason: .featureFlagDisabled))
    }

    @Test func checkAvailability_when_checker_returns_deviceNotSupported_then_state_transitions_to_unavailable_deviceNotSupported() async {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        checker.resultToReturn = .unavailable(reason: .deviceNotSupported)

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Then
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.state
            } onChange: {
                Task { @MainActor in
                    if case .unavailable = sut.state {
                        continuation.resume()
                    }
                }
            }
        }

        #expect(sut.state == .unavailable(reason: .deviceNotSupported))
    }

    @Test func checkAvailability_when_checker_returns_siteNotEligible_then_state_transitions_to_unavailable_siteNotEligible() async {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        checker.resultToReturn = .unavailable(reason: .siteNotEligible)

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Then
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.state
            } onChange: {
                Task { @MainActor in
                    if case .unavailable = sut.state {
                        continuation.resume()
                    }
                }
            }
        }

        #expect(sut.state == .unavailable(reason: .siteNotEligible))
    }

    // MARK: - Checker invocation

    @Test func init_then_calls_checker_exactly_once() async {
        // Given
        let checker = MockPOSTapToPayAvailabilityChecker()
        checker.resultToReturn = .available

        // When
        let sut = POSTapToPayAvailabilityController(availabilityChecker: checker)

        // Wait for init Task to complete
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.state
            } onChange: {
                Task { @MainActor in
                    continuation.resume()
                }
            }
        }

        // Then
        #expect(checker.checkAvailabilityCallCount == 1)
    }
}
