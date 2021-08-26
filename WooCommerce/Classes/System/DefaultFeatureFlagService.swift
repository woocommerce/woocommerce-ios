struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .largeTitles:
            return true
        case .shippingLabelsM2M3:
            return true
        case .shippingLabelsInternational:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsAddPaymentMethods:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsAddCustomPackages:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsMultiPackage:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .cardPresentSoftwareUpdates:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .orderEditing:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .cardPresentSeveralReadersFound:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
