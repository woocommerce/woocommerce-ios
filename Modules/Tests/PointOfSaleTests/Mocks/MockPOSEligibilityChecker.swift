import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var initialVisibility: Bool = false
    var visibility: Bool = false
    var eligibility: POSEligibilityState = .eligible

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    func checkVisibility() async -> Bool {
        visibility
    }

    func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState {
        eligibility
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .ineligible(reason: ineligibleReason)
    }
}
