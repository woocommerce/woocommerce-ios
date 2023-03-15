import Storage

enum BetaFeature: String, CaseIterable {
    case viewAddOns
    case productSKUScanner
    case couponManagement
    case inAppPurchases
    case productMultiSelection
}

extension BetaFeature {
    var title: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsTitle
        case .productSKUScanner:
            return Localization.productSKUScannerTitle
        case .couponManagement:
            return Localization.couponManagementTitle
        case .inAppPurchases:
            return Localization.inAppPurchasesManagementTitle
        case .productMultiSelection:
            return Localization.productMultiSelectionTitle
        }
    }

    var description: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsDescription
        case .productSKUScanner:
            return Localization.productSKUScannerDescription
        case .couponManagement:
            return Localization.couponManagementDescription
        case .inAppPurchases:
            return Localization.inAppPurchasesManagementDescription
        case .productMultiSelection:
            return Localization.productMultiSelectionDescription
        }
    }

    var settingsKey: WritableKeyPath<GeneralAppSettings, Bool> {
        switch self {
        case .viewAddOns:
            return \.isViewAddOnsSwitchEnabled
        case .productSKUScanner:
            return \.isProductSKUInputScannerSwitchEnabled
        case .couponManagement:
            return \.isCouponManagementSwitchEnabled
        case .inAppPurchases:
            return \.isInAppPurchasesSwitchEnabled
        case .productMultiSelection:
            return \.isProductMultiSelectionSwitchEnabled
        }
    }

    /// This is intended for removal, and new specific analytic stats should not be set here.
    /// When `viewAddOns` is removed, we can remove this property and always use the `settingsBetaFeatureToggled` event
    var analyticsStat: WooAnalyticsStat {
        switch self {
        case .viewAddOns:
            return .settingsBetaFeaturesOrderAddOnsToggled
        default:
            return .settingsBetaFeatureToggled
        }
    }

    var isAvailable: Bool {
        switch self {
        case .inAppPurchases:
            return ServiceLocator.featureFlagService.isFeatureFlagEnabled(.inAppPurchases)
        case .productMultiSelection:
            return ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productMultiSelectionM1)
        default:
            return true
        }
    }

    static var availableFeatures: [Self] {
        allCases.filter(\.isAvailable)
    }

    func analyticsProperties(toggleState enabled: Bool) -> [String: WooAnalyticsEventPropertyType] {
        var properties = ["state": enabled ? "on" : "off"]
        if analyticsStat == .settingsBetaFeatureToggled {
            properties["feature_name"] = self.rawValue
        }
        return properties
    }
}

extension GeneralAppSettingsStorage {
    func betaFeatureEnabled(_ feature: BetaFeature) -> Bool {
        guard feature.isAvailable else {
            return false
        }
        return value(for: feature.settingsKey)
    }

    func betaFeatureEnabledBinding(_ feature: BetaFeature) -> Binding<Bool> {
        Binding(get: {
            betaFeatureEnabled(feature)
        }, set: { newValue in
            try? setBetaFeatureEnabled(feature, enabled: newValue)
        })
    }

    func setBetaFeatureEnabled(_ feature: BetaFeature, enabled: Bool) throws {
        let event = WooAnalyticsEvent(statName: feature.analyticsStat,
                                      properties: feature.analyticsProperties(toggleState: enabled))
        ServiceLocator.analytics.track(event: event)
        try setValue(enabled, for: feature.settingsKey)
    }
}

extension BetaFeature: Identifiable {
    var id: String {
        description
    }
}

private extension BetaFeature {
    enum Localization {
        static let viewAddOnsTitle = NSLocalizedString(
            "View Add-Ons",
            comment: "Cell title on the beta features screen to enable the order add-ons feature")
        static let viewAddOnsDescription = NSLocalizedString(
            "Test out viewing Order Add-Ons as we get ready to launch",
            comment: "Cell description on the beta features screen to enable the order add-ons feature")

        static let productSKUScannerTitle = NSLocalizedString(
            "Product SKU Scanner",
            comment: "Cell title on beta features screen to enable product SKU input scanner in inventory settings.")
        static let productSKUScannerDescription = NSLocalizedString(
            "Test out scanning a barcode for a product SKU in the product inventory settings",
            comment: "Cell description on beta features screen to enable product SKU input scanner in inventory settings.")

        static let couponManagementTitle = NSLocalizedString(
            "Coupon Management",
            comment: "Cell title on beta features screen to enable coupon management")
        static let couponManagementDescription = NSLocalizedString(
            "Test out managing coupons as we get ready to launch",
            comment: "Cell description on beta features screen to enable coupon management")

        static let inAppPurchasesManagementTitle = NSLocalizedString(
            "In-app purchases",
            comment: "Cell title on beta features screen to enable in-app purchases")
        static let inAppPurchasesManagementDescription = NSLocalizedString(
            "Test out in-app purchases as we get ready to launch",
            comment: "Cell description on beta features screen to enable in-app purchases")

        static let productMultiSelectionTitle = NSLocalizedString(
            "Product Multi-Selection",
            comment: "Cell title on beta features screen to enable Product Multi-Selection")
        static let productMultiSelectionDescription = NSLocalizedString(
            "Test out Product Multi-Selection as we get ready to launch",
            comment: "Cell description on beta features screen to enable Product Multi-Selection")
    }
}
