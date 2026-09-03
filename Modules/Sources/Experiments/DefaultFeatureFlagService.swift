import enum WooFoundationCore.BuildConfiguration

public struct DefaultFeatureFlagService: FeatureFlagService {
    public init() {}

    public func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        let buildConfig = BuildConfiguration.current

        switch featureFlag {
        case .updateOrderOptimistically:
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
        case .manualErrorHandlingForSiteCredentialLogin:
            return true
        case .betterCustomerSelectionInOrder:
            return true
        case .productBundlesInOrderForm:
            return true
        case .customLoginUIForAccountCreation:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .scanToUpdateInventory:
            return true
        case .splitViewInProductsTab:
            return true
        case .pointOfSale:
            return buildConfig == .localDeveloper || buildConfig == .alpha
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
        case .productImageOptimizedHandling:
            return true
        case .orderAddressMapSearch:
            return true
        case .ciabBookings:
            return false
        case .pointOfSaleRoles:
            return false
        case .pointOfSaleCustomAmounts:
            return buildConfig == .localDeveloper
        case .pointOfSaleScanToPay:
            return buildConfig == .localDeveloper
        case .pointOfSaleMarkOrderAsPaid:
            return buildConfig == .localDeveloper
        case .pointOfSaleTapToPay:
            return true
        case .selfDrivenPushToken:
            return true
        case .clientSideDashboardBanner:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .ageRangeRequirementsCompliance:
            return true
        case .ciabBookingReschedule:
            return false
        case .loggedOutFFPanel:
            return !buildConfig.isProduction
        case .wooAIAssistant:
            return true
        case .arParcelFitting:
            return true
        case .smarterNotifications:
            return true
        case .starReceiptPrinterSupport:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        case .posServerCalculatedRefunds:
            return true
        default:
            return true
        }
    }
}
