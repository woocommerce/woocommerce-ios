import Foundation
import Yosemite
import Experiments

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product using AI" feature.
    func isEligible(storeHasProducts: Bool) -> Bool
}

/// Checks the eligibility for the "add product using AI" feature.
final class ProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    func isEligible(storeHasProducts: Bool) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.productCreationAI) else {
            return false
        }

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
