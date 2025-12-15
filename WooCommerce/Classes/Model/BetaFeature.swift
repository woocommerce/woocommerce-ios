import Combine
import Foundation
import Storage
import protocol WooFoundation.WooAnalyticsEventPropertyType
import WooFoundationCore

enum BetaFeature: String, CaseIterable {
    case viewAddOns
    case applicationPasswords
    case posLocalCatalog
}

extension BetaFeature {
    var title: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsTitle
        case .applicationPasswords:
            return Localization.applicationPasswordsTitle
        case .posLocalCatalog:
            return Localization.posLocalCatalogTitle
        }
    }

    var description: String {
        switch self {
        case .viewAddOns:
            return Localization.viewAddOnsDescription
        case .applicationPasswords:
            return Localization.applicationPasswordsDescription
        case .posLocalCatalog:
            return Localization.posLocalCatalogDescription
        }
    }

    var settingsKey: WritableKeyPath<GeneralAppSettings, Bool> {
        switch self {
        case .viewAddOns:
            return \.isViewAddOnsSwitchEnabled
        case .applicationPasswords:
            return \.isApplicationPasswordsSwitchEnabled
        case .posLocalCatalog:
            return \.isPOSLocalCatalogSwitchEnabled
        }
    }

    /// This is intended for removal, and new specific analytic stats should not be set here.
    /// When `viewAddOns` is removed, we can remove this property and always use the `settingsBetaFeatureToggled` event
    var analyticsStat: WooAnalyticsStat {
        switch self {
        case .viewAddOns:
            return .settingsBetaFeaturesOrderAddOnsToggled
        case .applicationPasswords:
            return .settingsBetaFeaturesApplicationPasswordsToggled
        case .posLocalCatalog:
            return .settingsBetaFeaturesPOSLocalCatalogToggled
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

extension BetaFeature {
    typealias DescriptionLink = (text: String, url: URL)

    var descriptionLink: DescriptionLink? {
        switch self {
        case .viewAddOns:
            return nil
        case .applicationPasswords:
            guard let url = URL(string: Constants.applicationPasswordsDocURL) else {
                return nil
            }

            return DescriptionLink(
                text: Localization.applicationPasswordsDescriptionLinkText,
                url: url
            )
        case .posLocalCatalog:
            return nil
        }
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

        static let applicationPasswordsTitle = NSLocalizedString(
            "experimentalFeatures.applicationPasswords.title",
            value: "Application Passwords",
            comment: "Cell title on the beta features screen to enable the application passwords feature")
        static let applicationPasswordsDescription = NSLocalizedString(
            "experimentalFeatures.applicationPasswords.description",
            value: "Enable %@ to let the app fetch data directly from your WooCommerce site rather than via Jetpack connections",
            comment: "Cell description on the beta features screen to enable application passwords feature. The placeholder will be replaced by a link title."
        )

        static let applicationPasswordsDescriptionLinkText = NSLocalizedString(
            "experimentalFeatures.applicationPasswords.description.linkText",
            value: "Application Passwords",
            comment: "Link text to open Application Passwords documentation page"
        )

        static let posLocalCatalogTitle = NSLocalizedString(
            "experimentalFeatures.posLocalCatalog.title",
            value: "POS Local Catalog",
            comment: "Cell title on the beta features screen to enable the POS local catalog feature")
        static let posLocalCatalogDescription = NSLocalizedString(
            "experimentalFeatures.posLocalCatalog.description",
            value: "Store your product catalog locally for faster access in Point of Sale",
            comment: "Cell description on the beta features screen to enable the POS local catalog feature")
    }

    enum Constants {
        static let applicationPasswordsDocURL =
            "https://wordpress.com/support/security/two-step-authentication/application-specific-passwords/"
    }
}
