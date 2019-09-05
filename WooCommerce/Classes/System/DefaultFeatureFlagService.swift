struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .stats:
            return BuildConfiguration.current == .localDeveloper
        default:
            return true
        }
    }
}
