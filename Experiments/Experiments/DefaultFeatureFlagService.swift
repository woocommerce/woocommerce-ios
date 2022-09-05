public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .barcodeScanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .jetpackConnectionPackageSupport:
            return true
        case .hubMenu:
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
        case .backgroundProductImageUpload:
            return true
        case .appleIDAccountDeletion:
            return true
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
        case .storeWidgets:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
