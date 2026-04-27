import Experiments
import Foundation

/// Gates whether the WooAI Assistant feature is available to the current user.
///
/// PR A1 establishes the gate. Subsequent PRs in the WooAI Assistant
/// sequence will introduce module code, UI, and entry points - all
/// behind this checker.
struct AIAssistantEligibilityChecker {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.featureFlagService = featureFlagService
    }

    /// `true` when the WooAI Assistant feature flag is enabled for the current build.
    var isEligible: Bool {
        featureFlagService.isFeatureFlagEnabled(.wooAIAssistant)
    }
}
