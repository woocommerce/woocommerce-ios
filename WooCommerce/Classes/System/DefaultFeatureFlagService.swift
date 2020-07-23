struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .editProducts:
            return true
        case .editProductsRelease2:
            return true
        case .editProductsRelease3:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .readonlyProductVariants:
            return true
        case .refunds:
            return true
        case .inAppFeedback:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
