import Foundation
@testable import PointOfSale

/// Mock implementation of POSLocalCatalogEligibilityServiceProtocol for testing
@MainActor
public final class MockPOSLocalCatalogEligibilityService: @MainActor POSLocalCatalogEligibilityServiceProtocol {
    public var eligibilityState: POSLocalCatalogEligibilityState
    public var refreshCallCount = 0

    public init(eligibilityState: POSLocalCatalogEligibilityState = .eligible) {
        self.eligibilityState = eligibilityState
    }

    public func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        refreshCallCount += 1
        return eligibilityState
    }
}
