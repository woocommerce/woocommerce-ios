import WooFoundationCore

public struct OverridableFeatureFlagService: FeatureFlagService {
    private let base: FeatureFlagService
    private let overrides: FeatureFlagOverrideStore

    public init(base: FeatureFlagService, overrides: FeatureFlagOverrideStore) {
        self.base = base
        self.overrides = overrides
    }

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current
        if buildConfig == .localDeveloper || buildConfig == .alpha,
            let override = overrides.overrideValue(for: featureFlag) {
            return override
        }

        return base.isFeatureFlagEnabled(featureFlag)
    }
}
