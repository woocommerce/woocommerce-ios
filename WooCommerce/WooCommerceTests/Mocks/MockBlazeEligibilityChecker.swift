@testable import WooCommerce
import Foundation
import Yosemite

/// Mock version of `BlazeEligibilityChecker` for easier unit testing.
final class MockBlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {

    private let isSiteEligible: Bool
    private let isProductEligible: Bool
    private(set) var isSiteEligibleInvoked: Bool = false

    init(isSiteEligible: Bool = false, isProductEligible: Bool = false) {
        self.isSiteEligible = isSiteEligible
        self.isProductEligible = isProductEligible
    }

    func isSiteEligible(_ site: Site) async -> Bool {
        isSiteEligibleInvoked = true
        return isSiteEligible
    }

    func isProductEligible(site: Site, product: WooCommerce.ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        isProductEligible
    }
}
