import Yosemite
import Foundation

extension SupportFormViewModel {
    /// Maps API support area type to the corresponding form area.
    ///
    static func area(for supportAreaType: SupportAreaType) -> Area {
        let metadataProvider = SupportFormMetadataProvider()
        switch supportAreaType {
        case .mobileApp:
            return .init(title: Localization.mobileApp, datasource: MobileAppSupportDataSource(metadataProvider: metadataProvider))
        case .cardReader:
            return .init(title: Localization.ipp, datasource: IPPSupportDataSource(metadataProvider: metadataProvider))
        case .wooPayments:
            return .init(title: Localization.wcPayments, datasource: WCPaySupportDataSource(metadataProvider: metadataProvider))
        case .wooCommercePlugin:
            return .init(title: Localization.wcPlugin, datasource: WCPluginsSupportDataSource(metadataProvider: metadataProvider))
        case .otherExtensionPlugin:
            return .init(title: Localization.otherPlugin, datasource: OtherPluginsSupportDataSource(metadataProvider: metadataProvider))
        }
    }

    /// Generates a subject line based on the support area type.
    ///
    static func subject(for supportAreaType: SupportAreaType) -> String {
        switch supportAreaType {
        case .mobileApp:
            return SubjectLocalization.mobileApp
        case .cardReader:
            return SubjectLocalization.cardReader
        case .wooPayments:
            return SubjectLocalization.wooPayments
        case .wooCommercePlugin:
            return SubjectLocalization.wooCommercePlugin
        case .otherExtensionPlugin:
            return SubjectLocalization.otherPlugin
        }
    }
}

private extension SupportFormViewModel {
    enum SubjectLocalization {
        static let mobileApp = NSLocalizedString(
            "supportFormViewModel.subject.mobileApp",
            value: "Mobile App Support Request",
            comment: "Subject line for auto-created support tickets for mobile app issues"
        )
        static let cardReader = NSLocalizedString(
            "supportFormViewModel.subject.cardReader",
            value: "Card Reader Support Request",
            comment: "Subject line for auto-created support tickets for card reader/IPP issues"
        )
        static let wooPayments = NSLocalizedString(
            "supportFormViewModel.subject.wooPayments",
            value: "WooPayments Support Request",
            comment: "Subject line for auto-created support tickets for WooPayments issues"
        )
        static let wooCommercePlugin = NSLocalizedString(
            "supportFormViewModel.subject.wooCommercePlugin",
            value: "WooCommerce Plugin Support Request",
            comment: "Subject line for auto-created support tickets for WooCommerce plugin issues"
        )
        static let otherPlugin = NSLocalizedString(
            "supportFormViewModel.subject.otherPlugin",
            value: "Plugin Support Request",
            comment: "Subject line for auto-created support tickets for other plugin/extension issues"
        )
    }
}
