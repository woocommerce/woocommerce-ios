import Foundation
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
@testable import WooCommerce

@MainActor
final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var eligibility: POSEligibilityState = .eligible

    func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState {
        eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
