@testable import WooCommerce
import Foundation
import Yosemite

/// Mock version of `BlazeEligibilityChecker` for easier unit testing.
final class MockBlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {

    private let isSiteEligible: Bool
    private let isProductEligible: Bool

    init(isSiteEligible: Bool = false, isProductEligible: Bool = false) {
        self.isSiteEligible = isSiteEligible
        self.isProductEligible = isProductEligible
    }

    func isSiteEligible(_ site: Site) -> Bool {
        return isSiteEligible
    }

    func isProductEligible(site: Site, product: WooCommerce.ProductFormDataModel, isPasswordProtected: Bool) -> Bool {
        isProductEligible
    }
}
