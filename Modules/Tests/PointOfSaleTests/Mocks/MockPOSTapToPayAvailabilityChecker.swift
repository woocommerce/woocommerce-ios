import Foundation
@testable import PointOfSale

final class MockPOSTapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking {
    /// Configures the result returned by `checkAvailability()`.
    var resultToReturn: POSTapToPayAvailabilityState = .available

    /// Records how many times `checkAvailability()` was called.
    var checkAvailabilityCallCount = 0

    func checkAvailability() async -> POSTapToPayAvailabilityState {
        checkAvailabilityCallCount += 1
        return resultToReturn
    }
}
