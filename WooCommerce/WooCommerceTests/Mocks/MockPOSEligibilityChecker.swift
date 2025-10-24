import Foundation
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
import protocol PointOfSale.POSLocalCatalogEligibilityServiceProtocol
@testable import WooCommerce

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var localCatalogEligibilityService: (any POSLocalCatalogEligibilityServiceProtocol)? = nil
    var eligibility: POSEligibilityState = .eligible

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
