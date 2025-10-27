import Foundation
@testable import Yosemite

final class MockPOSCatalogEligibilityChecker: POSCatalogEligibilityChecking {
    var isEligible = true
    var isCatalogEligibleForSyncCallCount = 0

    func isCatalogEligibleForSync() async -> Bool {
        isCatalogEligibleForSyncCallCount += 1
        return isEligible
    }
}
