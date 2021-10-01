protocol FeatureFlagService {
    /// Returns a boolean indicating if the feature is enabled
    ///
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool
}
