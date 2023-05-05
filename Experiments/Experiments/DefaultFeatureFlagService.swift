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
        case .inbox:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .splitViewInOrdersTab:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .loginPrologueOnboarding:
            return true
        case .loginErrorNotifications:
            return true
        case .loginMagicLinkEmphasisM2:
            return true
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
            return true
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
        case .tapToPayOnIPhoneMilestone2:
            return true
        case .domainSettings:
            return true
        case .jetpackSetupWithApplicationPassword:
            return true
        case .dashboardOnboarding:
            return true
        case .addCouponToOrder:
            return ( buildConfig == .localDeveloper || buildConfig == .alpha ) && !isUITesting
        case .productBundles:
            return true
        case .freeTrial:
            return true
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .compositeProducts:
            return true
        case .IPPUKExpansion:
            return true
        case .readOnlySubscriptions:
            return true
        case .productDescriptionAI:
            return true
        case .readOnlyGiftCards:
            return true
        case .hideStoreOnboardingTaskList:
            return true
        case .readOnlyMinMaxQuantities:
            return true
        default:
            return true
        }
    }
}
