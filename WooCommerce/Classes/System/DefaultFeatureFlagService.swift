struct DefaultFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .barcodeScanner:
            return BuildConfiguration.current == .localDeveloper || BuildConfiguration.current == .alpha
        case .editProducts:
            return true
        case .editProductsRelease2:
            return true
        case .editProductsRelease3:
            return BuildConfiguration.current == .localDeveloper || BuildConfiguration.current == .alpha
        case .readonlyProductVariants:
            return true
        case .refunds:
            return true
        default:
            return true
        }
    }
}
