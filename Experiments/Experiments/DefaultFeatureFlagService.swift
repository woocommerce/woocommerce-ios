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
            return true
        case .showInboxCTA:
            return true
        case .sideBySideViewForOrderForm:
            return true
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .shippingLabelsOnboardingM1:
            // We need to adapt this functionality to the new Woo Shipping plugin before enabling it
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
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .euShippingNotification:
            return true
        case .betterCustomerSelectionInOrder:
            return true
        case .hazmatShipping:
            return true
        case .giftCardInOrderForm:
            return true
        case .wooPaymentsPayoutsOverviewInPaymentsMenu:
            return true
        case .tapToPayOnIPhoneInUK:
            return true
        case .productBundlesInOrderForm:
            return true
        case .customLoginUIForAccountCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .scanToUpdateInventory:
            return true
        case .backendReceipts:
            return true
        case .splitViewInProductsTab:
            return true
        case .subscriptionsInOrderCreationUI:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .subscriptionsInOrderCreationCustomers:
            // Feature paused pfoUAQ-zw-p2#comment-510.
            return false
        case .pointOfSale:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .googleAdsCampaignCreationOnWebView:
            return true
        case .backgroundTasks:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .viewEditCustomFieldsInProductsAndOrders:
            return true
        case .blazeEvergreenCampaigns:
            return true
        case .revampedShippingLabelCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .blazeCampaignObjective:
            return true
        case .favoriteProducts:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .productGlobalUniqueIdentifierSupport:
            return true
        case .sendReceiptAfterPayment:
            return true
        case .sendReceiptsForPointOfSale:
            return true
        case .acceptCashForPointOfSale:
            return false
        case .tapToPayEducation:
            return true
        case .variableProductsInPointOfSale:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .hideSitesInStorePicker:
            return true
        default:
            return true
        }
    }
}
