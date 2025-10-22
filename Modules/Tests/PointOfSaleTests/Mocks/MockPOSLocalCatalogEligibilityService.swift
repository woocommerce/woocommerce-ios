import Foundation
@testable import Yosemite

/// Mock implementation of POSLocalCatalogEligibilityServiceProtocol for testing
public actor MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    public var stateToReturn: POSLocalCatalogEligibilityState
    public var getCallCount = 0
    public var refreshCallCount = 0

    public init(stateToReturn: POSLocalCatalogEligibilityState = .eligible) {
        self.stateToReturn = stateToReturn
    }

    public func getEligibilityState() async -> POSLocalCatalogEligibilityState {
        getCallCount += 1
        return stateToReturn
    }

    public func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        refreshCallCount += 1
        return stateToReturn
    }
}
