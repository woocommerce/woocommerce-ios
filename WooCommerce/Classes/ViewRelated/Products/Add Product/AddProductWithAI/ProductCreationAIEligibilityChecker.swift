import Foundation
import Yosemite
import Experiments

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product using AI" feature.
    var isEligible: Bool { get }
    var aiSource: AISource { get }
}

enum AISource {
    case none
    case `internal`
    case merchant
}

/// Checks the eligibility for the "add product using AI" feature.
final class ProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    private(set) var aiSource: AISource = .none

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    var isEligible: Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }

        // By default, check first if we provide AI capabilities from WPCOM/JP
        if site.isWordPressComStore || site.isAIAssistantFeatureActive {
            aiSource = .internal
            return true
        } else {
            // As fallback, allow personal API keys usage based on feature flag:
            switch featureFlagService.isFeatureFlagEnabled(.allowMerchantAIAPIKey) {
            case true:
                aiSource = .merchant
                return true
            case false:
                aiSource = .none
                return false
            }
        }
    }
}
