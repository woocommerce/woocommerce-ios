import Experiments

extension FeatureFlagService {
    /// Whether migrated Store Design System screens should replace their legacy implementations.
    var usesStoreDesignSystem: Bool {
        isFeatureFlagEnabled(.storeDesignSystem)
    }
}
