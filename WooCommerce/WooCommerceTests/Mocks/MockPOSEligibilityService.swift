import Foundation
import protocol Yosemite.POSEligibilityServiceProtocol

final class MockPOSEligibilityService: POSEligibilityServiceProtocol {
    var cachedTabVisibility: [Int64: Bool] = [:]

    func loadCachedPOSTabVisibility(siteID: Int64) -> Bool? {
        cachedTabVisibility[siteID]
    }

    func setPOSTabVisibility(siteID: Int64, isVisible: Bool) {
        cachedTabVisibility[siteID] = isVisible
    }
}
