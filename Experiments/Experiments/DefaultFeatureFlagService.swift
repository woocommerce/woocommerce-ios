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
        case .whatsNewOnWooCommerce:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .pushNotificationsForAllStores:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .quickOrderPrototype:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .orderListFilters:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
