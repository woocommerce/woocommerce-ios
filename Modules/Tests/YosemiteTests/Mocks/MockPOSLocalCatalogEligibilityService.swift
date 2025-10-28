import Foundation
@testable import Yosemite

/// Mock actor for testing
actor MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    var eligibilityState: POSLocalCatalogEligibilityState = .eligible

    /// Set to ineligible for testing
    func setIneligible() {
        eligibilityState = .ineligible(reason: .featureFlagDisabled)
    }

    func updateVisibility(isPOSTabVisible: Bool) async {
        // No-op for tests
    }

    func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        return eligibilityState
    }
}
