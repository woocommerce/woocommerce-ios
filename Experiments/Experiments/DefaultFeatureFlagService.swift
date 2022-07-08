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
        case .hubMenu:
            return true
        case .systemStatusReport:
            return true
        case .couponView:
            return true
        case .productSKUInputScanner:
            return true
        case .inbox:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .bulkEditProductVariations:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .splitViewInOrdersTab:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .couponDeletion:
            return true
        case .couponEditing:
            return true
        case .couponCreation:
            return true
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .inPersonPaymentGatewaySelection:
            return true
        case .unifiedOrderEditing:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .backgroundProductImageUpload:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .consolidatedCardReaderManuals:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .appleIDAccountDeletion:
            return true
        default:
            return true
        }
    }
}
