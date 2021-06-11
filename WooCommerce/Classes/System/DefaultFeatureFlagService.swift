struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .largeTitles:
            return true
        case .shippingLabelsM2M3:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsM4:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .addOnsI1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .sitePlugins:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
