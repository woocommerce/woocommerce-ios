public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .productSKUInputScanner:
            return true
        case .inbox:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .splitViewInOrdersTab:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .newToWooCommerceLinkInLoginPrologue:
            return true
        case .loginPrologueOnboarding:
            return true
        case .loginErrorNotifications:
            return true
        case .loginPrologueOnboardingSurvey:
            return true
        case .loginMagicLinkEmphasis:
            return true
        case .loginMagicLinkEmphasisM2:
            return true
        case .promptToEnableCodInIppOnboarding:
            return true
        case .searchProductsBySKU:
            return true
        case .orderCreationSearchCustomers:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .wpcomSignup:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .inAppPurchases:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .storeCreationMVP:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .productsOnboarding:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
