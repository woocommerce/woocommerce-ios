public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .orderListFilters:
            return true
        case .jetpackConnectionPackageSupport:
            return true
        case .orderCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .hubMenu:
            return true
        case .systemStatusReport:
            return true
        case .couponView:
            return true
        case .productSKUInputScanner:
            return true
        case .canadaInPersonPayments:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .inbox:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .bulkEditProductVariations:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
