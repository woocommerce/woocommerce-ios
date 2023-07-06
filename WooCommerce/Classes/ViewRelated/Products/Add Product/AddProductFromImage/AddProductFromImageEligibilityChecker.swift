import Foundation
import Yosemite

/// Protocol for checking "add product from image" eligibility for easier unit testing.
protocol AddProductFromImageEligibilityCheckerProtocol {
    /// Checks if the user is eligible to participate in the A/B experiment.
    func isEligibleToParticipateInABTest() -> Bool

    /// Checks if the user is eligible for the "add product from image" feature.
    func isEligible() -> Bool
}

/// Checks the eligibility for the "add product from image" feature.
final class AddProductFromImageEligibilityChecker: AddProductFromImageEligibilityCheckerProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func isEligibleToParticipateInABTest() -> Bool {
        stores.sessionManager.defaultSite?.isWordPressComStore == true
    }

    func isEligible() -> Bool {
        // TODO: 10180 - A/B experiment check
        true
    }
}
