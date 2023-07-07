@testable import WooCommerce
import Foundation

/// Mock version of `AddProductFromImageEligibilityChecker` for easier unit testing.
final class MockAddProductFromImageEligibilityChecker: AddProductFromImageEligibilityCheckerProtocol {
    private let eligibleToParticipateInABTest: Bool
    private let eligible: Bool

    init(isEligibleToParticipateInABTest: Bool = false, isEligible: Bool = false) {
        self.eligibleToParticipateInABTest = isEligibleToParticipateInABTest
        self.eligible = isEligible
    }

    func isEligibleToParticipateInABTest() -> Bool {
        eligibleToParticipateInABTest
    }

    func isEligible() -> Bool {
        eligible
    }
}
