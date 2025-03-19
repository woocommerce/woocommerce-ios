import Foundation
import Yosemite
import Experiments

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product using AI" feature.
    var isEligible: Bool { get }
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

    var isEligible: Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }

        // By default, check if we provide AI capabilities form WPCOM/JP
        if site.isWordPressComStore || site.isAIAssistantFeatureActive {
            return true
        } else {
            // As fallback, allow personal API keys usage based on feature flag:
            return featureFlagService.isFeatureFlagEnabled(.allowMerchantAIAPIKey)
        }
    }
}
