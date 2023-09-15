import Foundation
import Yosemite
import Experiments

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product from image" feature.
    func isEligible() -> Bool
}

/// Checks the eligibility for the "add product using AI" feature.
final class ProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let stores: StoresManager
    private let storeHasProducts: Bool

    init(stores: StoresManager = ServiceLocator.stores,
         storeHasProducts: Bool) {
        self.stores = stores
        self.storeHasProducts = storeHasProducts
    }

    func isEligible() -> Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }

        // Should be a new user with zero products
        guard storeHasProducts == false else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssitantFeatureActive
    }
}
