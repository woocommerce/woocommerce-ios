import Foundation
import protocol Yosemite.POSEligibilityServiceProtocol

final class MockPOSEligibilityService: POSEligibilityServiceProtocol {
    var cachedTabVisibility: [Int64: Bool] = [:]

    func loadPOSTabVisibility(siteID: Int64) -> Bool? {
        cachedTabVisibility[siteID]
    }
}
