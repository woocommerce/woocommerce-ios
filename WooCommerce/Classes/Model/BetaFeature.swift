import Combine
import Storage
import protocol WooFoundation.WooAnalyticsEventPropertyType

enum BetaFeature: String, CaseIterable {
    case viewAddOns
    case inAppPurchases
    case pointOfSale
}

extension BetaFeature {
    var title: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsTitle
        case .inAppPurchases:
            return Localization.inAppPurchasesManagementTitle
        case .pointOfSale:
            return Localization.pointOfSaleTitle
        }
    }

    var description: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsDescription
        case .inAppPurchases:
            return Localization.inAppPurchasesManagementDescription
        case .pointOfSale:
            return Localization.pointOfSaleDescription
        }
    }

    var settingsKey: WritableKeyPath<GeneralAppSettings, Bool> {
        switch self {
        case .viewAddOns:
            return \.isViewAddOnsSwitchEnabled
        case .inAppPurchases:
            return \.isInAppPurchasesSwitchEnabled
        case .pointOfSale:
            return \.isPointOfSaleEnabled
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
        value(for: feature.settingsKey)
    }

    func betaFeatureEnabledPublisher(_ feature: BetaFeature) -> AnyPublisher<Bool, Never> {
        publisher(for: feature.settingsKey)
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

        static let inAppPurchasesManagementTitle = NSLocalizedString(
            "In-app purchases",
            comment: "Cell title on beta features screen to enable in-app purchases")
        static let inAppPurchasesManagementDescription = NSLocalizedString(
            "Test out in-app purchases as we get ready to launch",
            comment: "Cell description on beta features screen to enable in-app purchases")

        static let pointOfSaleTitle = NSLocalizedString(
            "betaFeature.pointOfSale.title",
            value: "Point Of Sale",
            comment: "Cell title on beta features screen to enable the Point Of Sale feature")
        static let pointOfSaleDescription = NSLocalizedString(
            "betaFeature.pointOfSale.description",
            value: "Test out Point Of Sale as we get ready to launch",
            comment: "Cell description on beta features screen to enable the Point Of Sale feature")
    }
}
