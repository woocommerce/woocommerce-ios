import Yosemite

/// Mock for `POSLocalCatalogEligibilityServiceProtocol`: hands back the configured states without evaluating
/// anything.
actor MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {

    private var cachedStates: [Int64: POSLocalCatalogEligibilityState]

    init(cachedStates: [Int64: POSLocalCatalogEligibilityState] = [:]) {
        self.cachedStates = cachedStates
    }

    func catalogEligibility(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState {
        cachedStates[siteID] ?? .eligible
    }

    func cachedCatalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState? {
        cachedStates[siteID]
    }

    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async throws {
        // No-op for tests
    }

    @discardableResult
    func refreshEligibilityState(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState {
        cachedStates[siteID] ?? .eligible
    }

    func isLocalCatalogFeatureEnabled() async -> Bool {
        true
    }
}
