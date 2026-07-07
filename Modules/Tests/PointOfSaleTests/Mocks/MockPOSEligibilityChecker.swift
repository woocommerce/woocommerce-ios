import Foundation
@testable import PointOfSale

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var initialVisibility: Bool = false
    var visibility: Bool = false
    var eligibility: POSEligibilityState = .eligible
    private(set) var checkEligibilityCallCount = 0

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    @MainActor
    func checkVisibility() async -> Bool {
        visibility
    }

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        checkEligibilityCallCount += 1
        return eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
