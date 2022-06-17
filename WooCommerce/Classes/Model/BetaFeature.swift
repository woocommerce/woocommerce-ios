import Storage

enum BetaFeature: CaseIterable {
    case viewAddOns
    case productSKUScanner
    case couponManagement
}

extension BetaFeature {
    var title: String {
        switch self {
        case .viewAddOns:
            return NSLocalizedString(
                "View Add-Ons",
                comment: "Cell title on the beta features screen to enable the order add-ons feature")
        case .productSKUScanner:
            return NSLocalizedString(
                "Product SKU Scanner",
                comment: "Cell title on beta features screen to enable product SKU input scanner in inventory settings.")
        case .couponManagement:
            return NSLocalizedString(
                "Coupon Management",
                comment: "Cell title on beta features screen to enable coupon management")
        }
    }

    var description: String {
        switch self {
        case .viewAddOns:
            return NSLocalizedString(
                "Test out viewing Order Add-Ons as we get ready to launch",
                comment: "Cell description on the beta features screen to enable the order add-ons feature")
        case .productSKUScanner:
            return NSLocalizedString(
                "Test out scanning a barcode for a product SKU in the product inventory settings",
                comment: "Cell description on beta features screen to enable product SKU input scanner in inventory settings.")
        case .couponManagement:
            return NSLocalizedString(
                "Test out managing coupons as we get ready to launch",
                comment: "Cell description on beta features screen to enable coupon management")
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
        }
    }

    var analyticsStat: WooAnalyticsStat? {
        switch self {
        case .viewAddOns:
            return .settingsBetaFeaturesOrderAddOnsToggled
        case .productSKUScanner:
            return nil
        case .couponManagement:
            return nil
        }
    }
}

extension GeneralAppSettingsStorage {
    func betaFeatureEnabled(_ feature: BetaFeature) -> Bool {
        value(for: feature.settingsKey)
    }

    func betaFeatureEnabledBinding(_ feature: BetaFeature) -> Binding<Bool> {
        Binding(get: {
            betaFeatureEnabled(feature)
        }, set: { newValue in
            try? setBetaFeatureEnabled(feature, enabled: newValue)
        })
    }

    func setBetaFeatureEnabled(_ feature: BetaFeature, enabled: Bool) throws {
        if let analyticStat = feature.analyticsStat {
            let event = WooAnalyticsEvent(statName: analyticStat, properties: ["state": enabled ? "on" : "off"])
            ServiceLocator.analytics.track(event: event)
        }
        try setValue(enabled, for: feature.settingsKey)
    }
}

extension BetaFeature {
    var isEnabled: Bool {
        ServiceLocator.generalAppSettings.value(for: settingsKey)
    }

    func setEnabled(_ value: Bool) {
        if let analyticStat = analyticsStat {
            let event = WooAnalyticsEvent(statName: analyticStat, properties: ["state": value ? "on" : "off"])
            ServiceLocator.analytics.track(event: event)
        }
        try? ServiceLocator.generalAppSettings.setValue(value, for: settingsKey)
    }

    func isEnabledBinding() -> Binding<Bool> {
        Binding(get: {
            ServiceLocator.generalAppSettings.value(for: settingsKey)
        }, set: { newValue in
            setEnabled(newValue)
        })
    }
}

extension BetaFeature: Identifiable {
    var id: String {
        description
    }
}
