import Foundation
@testable import WooCommerce

final class MockGoogleAdsEligibilityChecker: GoogleAdsEligibilityChecker {

    private var isEligible = false
    private(set) var siteEligibilityCheckTriggered = false

    init(isEligible: Bool) {
        self.isEligible = isEligible
    }

    func isSiteEligible(siteID: Int64) async -> Bool {
        siteEligibilityCheckTriggered = true
        return isEligible
    }
}
