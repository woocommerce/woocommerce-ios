import Experiments
import Foundation

/// Gates the WooAI Assistant feature behind its feature flag.
struct AIAssistantEligibilityChecker {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.featureFlagService = featureFlagService
    }

    var isEligible: Bool {
        featureFlagService.isFeatureFlagEnabled(.wooAIAssistant)
    }
}
