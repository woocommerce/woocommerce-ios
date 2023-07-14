import protocol Experiments.FeatureFlagService
import struct Yosemite.Site

/// AI-assisted features for product editing/creation.
enum ProductFormAIFeature: Equatable {
    case description
}

/// Checks the eligible AI features for product editing/creation.
final class ProductFormAIEligibilityChecker {
    private let site: Site?
    private let featureFlagService: FeatureFlagService

    init(site: Site?, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.site = site
        self.featureFlagService = featureFlagService
    }

    /// Checks if an AI feature is enabled.
    /// - Parameter feature: AI-assisted feature.
    /// - Returns: Whether the feature is supported.
    func isFeatureEnabled(_ feature: ProductFormAIFeature) -> Bool {
        site?.isWordPressComStore == true && featureFlagService.isFeatureFlagEnabled(.productDescriptionAI)
    }
}
