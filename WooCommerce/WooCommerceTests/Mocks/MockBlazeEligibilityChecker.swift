@testable import WooCommerce
import Foundation
import Yosemite

/// Mock version of `BlazeEligibilityChecker` for easier unit testing.
final class MockBlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {

    private var isSiteEligible: Bool
    private var isProductEligible: Bool

    private(set) var isSiteEligibleInvoked = false
    private(set) var siteEligibilityCheckCount = 0

    init(isSiteEligible: Bool = false, isProductEligible: Bool = false) {
        self.isSiteEligible = isSiteEligible
        self.isProductEligible = isProductEligible
    }

    func isSiteEligible(_ site: Site) async -> Bool {
        isSiteEligibleInvoked = true
        siteEligibilityCheckCount += 1
        return isSiteEligible
    }

    func isProductEligible(site: Site, product: WooCommerce.ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        isProductEligible
    }
}

// MARK: Test helper
extension MockBlazeEligibilityChecker {
    func updateSiteEligibility(_ isEligible: Bool) {
        isSiteEligible = isEligible
    }
}
