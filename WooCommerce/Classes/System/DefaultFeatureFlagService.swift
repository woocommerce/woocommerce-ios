struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .addProductVariations:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .cardPresentPayments:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsRelease2:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
