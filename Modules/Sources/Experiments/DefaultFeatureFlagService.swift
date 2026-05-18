import enum WooFoundationCore.BuildConfiguration

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
        case .updateOrderOptimistically:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .searchProductsBySKU:
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
        case .productBundlesInOrderForm:
            return true
        case .customLoginUIForAccountCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .scanToUpdateInventory:
            return true
        case .splitViewInProductsTab:
            return true
        case .subscriptionsInOrderCreationUI:
            // Feature paused pdqJU4-4mn-p2#comment-2067
            return false
        case .subscriptionsInOrderCreationCustomers:
            // Feature paused pdqJU4-4mn-p2#comment-2067
            return false
        case .pointOfSale:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .googleAdsCampaignCreationOnWebView:
            return true
        case .blazeEvergreenCampaigns:
            return true
        case .revampedShippingLabelCreation:
            return true
        case .blazeCampaignObjective:
            return true
        case .hideSitesInStorePicker:
            return true
        case .filterHistoryOnOrderAndProductLists:
            return true
        case .backgroundProductImageUpload:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .inventoryProductLabelsInPOS:
            return false
        case .productImageOptimizedHandling:
            return true
        case .pointOfSaleOrdersi1:
            return true
        case .pointOfSaleOrdersi2:
            return true
        case .orderAddressMapSearch:
            return true
        case .pointOfSaleHistoricalOrdersi1:
            return true
        case .pointOfSaleFTSSearch:
            return true
        case .ciabBookings:
            return !buildConfig.isProduction
        case .pointOfSaleCatalogAPI:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .pointOfSaleRefundsi1:
            return true
        case .pointOfSaleCustomAmounts:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .pointOfSalePhonePrototype:
            // Behind the flag for now — gates and UI follow in stacked PRs. Default to
            // localDeveloper only so alpha builds aren't affected until we're ready.
            return buildConfig == .localDeveloper
        case .pointOfSaleScanToPay:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .pointOfSaleMarkOrderAsPaid:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .pointOfSaleTapToPay:
            // Behind the flag while the TTP integration lands. localDeveloper-only so
            // alpha and beta keep showing only Cash + Card reader for now.
            return buildConfig == .localDeveloper
        case .selfDrivenPushToken:
            return false
        case .clientSideDashboardBanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .ageRangeRequirementsCompliance:
            return false
        case .ciabBookingReschedule:
            return !buildConfig.isProduction
        case .loggedOutFFPanel:
            return !buildConfig.isProduction
        case .aiSupportChat:
            return !buildConfig.isProduction
        case .wooAIAssistant:
            return true
        case .arParcelFitting:
            return true
        case .smarterNotifications:
            return !buildConfig.isProduction
        default:
            return true
        }
    }
}
