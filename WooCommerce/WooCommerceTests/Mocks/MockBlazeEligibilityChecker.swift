@testable import WooCommerce
import Foundation

/// Mock version of `BlazeEligibilityChecker` for easier unit testing.
final class MockBlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {
    private(set) var isSiteEligibleInvoked: Bool = false

    private let isSiteEligible: Bool
    private let isProductEligible: Bool

    init(isSiteEligible: Bool = false, isProductEligible: Bool = false) {
        self.isSiteEligible = isSiteEligible
        self.isProductEligible = isProductEligible
    }

    func isSiteEligible() async -> Bool {
        isSiteEligibleInvoked = true
        return isSiteEligible
    }

    func isProductEligible(product: WooCommerce.ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        isProductEligible
    }
}
