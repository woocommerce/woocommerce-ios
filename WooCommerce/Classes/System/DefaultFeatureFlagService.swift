struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .productList:
            return BuildConfiguration.current == .localDeveloper
        case .editProducts:
            return BuildConfiguration.current == .localDeveloper
        case .readonlyProductVariants:
            return BuildConfiguration.current == .localDeveloper
        case .stats:
            return true
        case .refunds:
            return BuildConfiguration.current == .localDeveloper
        default:
            return true
        }
    }
}
