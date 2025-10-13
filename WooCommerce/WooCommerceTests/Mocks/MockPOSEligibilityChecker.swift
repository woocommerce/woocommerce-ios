import Foundation
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
@testable import WooCommerce

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var eligibility: POSEligibilityState = .eligible

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
