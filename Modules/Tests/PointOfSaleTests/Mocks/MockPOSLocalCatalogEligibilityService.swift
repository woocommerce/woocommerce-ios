import Foundation
import Yosemite
@testable import PointOfSale

/// Mock implementation of POSLocalCatalogEligibilityServiceProtocol for testing
@MainActor
public final class MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    public var eligibilityState: POSLocalCatalogEligibilityState
    public var refreshCallCount = 0

    public init(eligibilityState: POSLocalCatalogEligibilityState = .eligible) {
        self.eligibilityState = eligibilityState
    }

    public func catalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        return eligibilityState
    }

    public func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        refreshCallCount += 1
        return eligibilityState
    }

    public func updateVisibility(isPOSTabVisible: Bool, for siteID: Int64) async { }
}
