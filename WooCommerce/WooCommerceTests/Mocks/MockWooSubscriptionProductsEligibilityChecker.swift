import Foundation
@testable import WooCommerce

final class MockWooSubscriptionProductsEligibilityChecker: WooSubscriptionProductsEligibilityCheckerProtocol {
    private let isEligible: Bool

    init(isEligible: Bool) {
        self.isEligible = isEligible
    }

    func isSiteEligible() -> Bool {
        isEligible
    }
}
