import protocol Experiments.FeatureFlagService
import struct Yosemite.Site

protocol ShareProductAIEligibilityChecker {
    var canGenerateShareProductMessageUsingAI: Bool { get }
}

struct DefaultShareProductAIEligibilityChecker: ShareProductAIEligibilityChecker {
    private let site: Site?

    init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite) {
        self.site = site
    }

    var canGenerateShareProductMessageUsingAI: Bool {
        guard let site else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
