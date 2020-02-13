struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .productList:
            return true
        case .editProducts:
            return BuildConfiguration.current == .localDeveloper || BuildConfiguration.current == .alpha
        case .editProductsRelease2:
            return BuildConfiguration.current == .localDeveloper || BuildConfiguration.current == .alpha
        case .readonlyProductVariants:
            return true
        case .stats:
            return true
        case .refunds:
            return true
        case .orderListRedesign:
            return BuildConfiguration.current == .localDeveloper
        default:
            return true
        }
    }
}
