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
            // We have a crash with this feature flag enabled. See https://github.com/woocommerce/woocommerce-ios/issues/10815
            return false
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .promptToEnableCodInIppOnboarding:
            return true
        case .searchProductsBySKU:
            return true
        case .inAppPurchases:
            return buildConfig == .localDeveloper || buildConfig == .alpha
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
        case .domainSettings:
            return true
        case .jetpackSetupWithApplicationPassword:
            return true
        case .dashboardOnboarding:
            return true
        case .addProductToOrderViaSKUScanner:
            return true
        case .productBundles:
            return true
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .compositeProducts:
            return true
        case .readOnlySubscriptions:
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
        case .sdkLessGoogleSignIn:
            return true
        case .shareProductAI:
            return true
        case .ordersWithCouponsM4:
            return true
        case .ordersWithCouponsM6:
            return true
        case .betterCustomerSelectionInOrder:
            return true
        case .manualTaxesInOrderM2:
            return true
        case .hazmatShipping:
            return true
        case .reusePaymentIntentOnRetryInPersonPayment:
            return true
        case .refreshOrderBeforeInPersonPayment:
            return true
        case .manualTaxesInOrderM3:
            return true
        case .productCreationAI:
            return true
        case .giftCardInOrderForm:
            return true
        case .wooPaymentsDepositsOverviewInPaymentsMenu:
            return (buildConfig == .localDeveloper || buildConfig == .alpha) && !isUITesting
        case .orderCustomAmountsM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .tapToPayOnIPhoneInUK:
            return buildConfig == .localDeveloper
        case .optimizedBlazeExperience:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
