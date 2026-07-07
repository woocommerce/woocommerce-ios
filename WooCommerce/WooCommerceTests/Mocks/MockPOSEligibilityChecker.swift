import Foundation
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
@testable import WooCommerce

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var eligibility: POSEligibilityState = .eligible
    private(set) var checkEligibilityCallCount = 0

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        checkEligibilityCallCount += 1
        return eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
