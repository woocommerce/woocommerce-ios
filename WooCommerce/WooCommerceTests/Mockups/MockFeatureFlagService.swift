@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        default:
            return false
        }
    }
}
