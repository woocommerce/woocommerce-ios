import Foundation
@testable import Yosemite

/// Mock implementation that can be used from any isolation context
final class MockPOSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    var isEligible = true
    var isCatalogEligibleForSyncCallCount = 0
    var eligibilityState: POSLocalCatalogEligibilityState = .eligible

    nonisolated func isCatalogEligibleForSync() async -> Bool {
        isCatalogEligibleForSyncCallCount += 1
        return isEligible
    }

    nonisolated func updateVisibility(isPOSTabVisible: Bool) async {
        // No-op for tests
    }

    nonisolated func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        return eligibilityState
    }
}
