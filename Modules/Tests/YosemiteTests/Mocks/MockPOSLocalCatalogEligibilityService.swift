import Foundation
@testable import Yosemite

/// Mock actor for testing
actor MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private var eligibilityStates: [Int64: POSLocalCatalogEligibilityState] = [:]

    /// Set eligibility for a specific site
    func setEligibility(_ state: POSLocalCatalogEligibilityState, for siteID: Int64) {
        eligibilityStates[siteID] = state
    }

    /// Set to ineligible for testing
    func setIneligible(for siteID: Int64) {
        eligibilityStates[siteID] = .ineligible(reason: .betaFeatureDisabled)
    }

    func catalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        return eligibilityStates[siteID] ?? .eligible
    }

    func cachedCatalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState? {
        eligibilityStates[siteID]
    }

    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async {
        // No-op for tests
    }

    func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        return eligibilityStates[siteID] ?? .eligible
    }

    var isLocalCatalogFeatureEnabledResult = true

    func isLocalCatalogFeatureEnabled() async -> Bool {
        isLocalCatalogFeatureEnabledResult
    }
}
