@testable import WooCommerce
import Foundation

/// Mock version of `ProductCreationAIEligibilityChecker` for easier unit testing.
final class MockProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let eligible: Bool

    init(isEligible: Bool = false) {
        self.eligible = isEligible
    }

    var isEligible: Bool {
        eligible
    }
}
