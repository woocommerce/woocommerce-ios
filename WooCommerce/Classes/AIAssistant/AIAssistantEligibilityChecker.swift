import Experiments
import Foundation
import struct Yosemite.Site

struct AIAssistantEligibilityChecker {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func isEligible(for site: Site?) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.wooAIAssistant), let site else {
            return false
        }
        return site.isWordPressComStore || site.isAIAssistantFeatureActive || site.isJetpackConnected
    }
}
