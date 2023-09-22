import protocol Experiments.FeatureFlagService
import struct Yosemite.Site

protocol ShareProductAIEligibilityChecker {
    var canGenerateShareProductMessageUsingAI: Bool { get }
}

struct DefaultShareProductAIEligibilityChecker: ShareProductAIEligibilityChecker {
    private let site: Site?
    private let featureFlagService: FeatureFlagService

    init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.site = site
        self.featureFlagService = featureFlagService
    }

    var canGenerateShareProductMessageUsingAI: Bool {
        guard featureFlagService.isFeatureFlagEnabled(.shareProductAI) else {
            return false
        }

        guard let site else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
