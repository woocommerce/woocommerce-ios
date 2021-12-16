public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .largeTitles:
            return true
        case .shippingLabelsM2M3:
            return true
        case .shippingLabelsInternational:
            return true
        case .shippingLabelsAddPaymentMethods:
            return true
        case .shippingLabelsAddCustomPackages:
            return true
        case .shippingLabelsMultiPackage:
            return true
        case .pushNotificationsForAllStores:
            return true
        case .orderListFilters:
            return true
        case .jetpackConnectionPackageSupport:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .orderCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .hubMenu:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .refundFees:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .systemStatusReport:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
