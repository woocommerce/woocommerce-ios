import Foundation
import Yosemite
import Experiments

/// Checks whether a store is eligible for Lightweight Storefront feature.
final class ThemeEligibilityUseCase {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func isEligible(site: Site) -> Bool {
        return site.isWordPressComStore
    }
}
