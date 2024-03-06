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
        case .inbox:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .sideBySideViewForOrderForm:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .searchProductsBySKU:
            return true
        case .inAppPurchasesDebugMenu:
            return buildConfig == .localDeveloper || buildConfig == .alpha
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
        case .domainSettings:
            return true
        case .jetpackSetupWithApplicationPassword:
            return true
        case .dashboardOnboarding:
            return true
        case .productBundles:
            return true
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .compositeProducts:
            return true
        case .productDescriptionAI:
            return true
        case .productDescriptionAIFromStoreOnboarding:
            return !isUITesting
        case .readOnlyGiftCards:
            return true
        case .hideStoreOnboardingTaskList:
            return true
        case .readOnlyMinMaxQuantities:
            return true
        case .storeCreationNotifications:
            return true
        case .euShippingNotification:
            return true
        case .shareProductAI:
            return true
        case .betterCustomerSelectionInOrder:
            return true
        case .hazmatShipping:
            return true
        case .productCreationAI:
            return true
        case .giftCardInOrderForm:
            return true
        case .wooPaymentsDepositsOverviewInPaymentsMenu:
            return true
        case .tapToPayOnIPhoneInUK:
            return true
        case .productBundlesInOrderForm:
            return true
        case .customLoginUIForAccountCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .scanToUpdateInventory:
            return true
        case .blazei3NativeCampaignCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .backendReceipts:
            return true
        case .splitViewInProductsTab:
            return true
        case .customRangeInMyStoreAnalytics:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .connectivityTool:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .appPasswordTutorial:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
