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
            return false
        case .loginPrologueOnboarding:
            return true
        case .loginErrorNotifications:
            return true
        case .loginMagicLinkEmphasis:
            return true
        case .loginMagicLinkEmphasisM2:
            return true
        case .productMultiselectionM1:
            return buildConfig == .localDeveloper || buildConfig == .alpha
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
        case .systemStatusReportInSupportRequest:
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
        case .supportRequests:
            return true
        case .simplifyProductEditing:
            return buildConfig == .localDeveloper || buildConfig == .alpha
        default:
            return true
        }
    }
}
