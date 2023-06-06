import protocol Experiments.FeatureFlagService
import struct Yosemite.Site

struct ShareProductAIEligibilityChecker {
    private let site: Site?
    private let featureFlagService: FeatureFlagService

    init(site: Site?, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.site = site
        self.featureFlagService = featureFlagService
    }

    var canGenerateShareProductMessageUsingAI: Bool {
        site?.isWordPressComStore == true && featureFlagService.isFeatureFlagEnabled(.shareProductAI)
    }
}
