struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .productList:
            return true
        case .editProducts:
            return BuildConfiguration.current == .localDeveloper
        case .readonlyProductVariants:
            return true
        case .stats:
            return true
        case .refunds:
            return BuildConfiguration.current == .localDeveloper
        default:
            return true
        }
    }
}
