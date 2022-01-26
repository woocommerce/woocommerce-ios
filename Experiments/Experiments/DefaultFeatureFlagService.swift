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
            return true
        case .orderCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .hubMenu:
            return true
        case .systemStatusReport:
            return true
        case .stripeExtensionInPersonPayments:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .myStoreTabUpdates:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .couponManagement:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .productSKUInputScanner:
            return true
        case .taxLinesInSimplePayments:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
