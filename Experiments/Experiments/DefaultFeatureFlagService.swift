public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        /// Whether this is a UI test run.
        ///
        /// This can be used to enable/disable a feature flag specifically for UI testing.
        ///
        let isUITesting = CommandLine.arguments.contains("-ui_testing")

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
            return false
        case .loginPrologueOnboarding:
            return true
        case .loginErrorNotifications:
            return true
        case .loginMagicLinkEmphasis:
            return false
        case .loginMagicLinkEmphasisM2:
            return true
        case .productMultiSelectionM1:
            return buildConfig == .localDeveloper  || buildConfig == .alpha
        case .promptToEnableCodInIppOnboarding:
            return true
        case .searchProductsBySKU:
            return true
        case .inAppPurchases:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .storeCreationMVP:
            return true
        case .storeCreationM2:
            return true
        case .storeCreationM2WithInAppPurchasesEnabled:
            return false
        case .storeCreationM3Profiler:
            return false
        case .justInTimeMessagesOnDashboard:
            return true
        case .IPPInAppFeedbackBanner:
            return true
        case .performanceMonitoring,
                .performanceMonitoringCoreData,
                .performanceMonitoringFileIO,
                .performanceMonitoringNetworking,
                .performanceMonitoringViewController,
                .performanceMonitoringUserInteraction:
            // Disabled by default to avoid costs spikes, unless in internal testing builds.
            return buildConfig == .alpha
        case .tapToPayOnIPhone:
            // It is not possible to get the TTPoI entitlement for an enterprise certificate,
            // so we should not enable this for alpha builds.
            return buildConfig == .localDeveloper || buildConfig == .appStore
        case .tapToPayOnIPhoneSetupFlow:
            // It is not possible to get the TTPoI entitlement for an enterprise certificate,
            // so we should not enable this for alpha builds.
            return buildConfig == .localDeveloper
        case .domainSettings:
            return true
        case .simplifyProductEditing:
            // Enabled for the A/B experiment treatment group only
            // Disabled for the control group and UI testing
            return ABTest.simplifiedProductEditing.variation == .treatment && !isUITesting
        case .jetpackSetupWithApplicationPassword:
            return true
        case .dashboardOnboarding:
            return true
        case .addCouponToOrder:
            return ( buildConfig == .localDeveloper || buildConfig == .alpha ) && !isUITesting
        case .productBundles:
            return true
        case .freeTrial:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .compositeProducts:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
