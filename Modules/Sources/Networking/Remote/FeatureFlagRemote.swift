import Foundation

/// Protocol for `FeatureFlagsRemote` mainly used for mocking.
///
public protocol FeatureFlagRemoteProtocol {
    func loadAllFeatureFlags() async throws -> [RemoteFeatureFlag: Bool]
}

/// Feature Flags: Remote Endpoints
///
public class FeatureFlagRemote: Remote, FeatureFlagRemoteProtocol {
    public func loadAllFeatureFlags() async throws -> [RemoteFeatureFlag: Bool] {
        let parameters: [String: String] = [
            ParameterKeys.platform: "ios",
            ParameterKeys.marketingVersion: Bundle.main.marketingVersion,
        ]

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Paths.lookup, parameters: parameters)
        let valuesByFeatureFlagString: [String: Bool] = try await enqueue(request)
        return Dictionary(uniqueKeysWithValues: valuesByFeatureFlagString.compactMap { key, value in
            guard let featureFlag = RemoteFeatureFlag(rawValue: key) else {
                return nil
            }
            return (featureFlag, value)
        })
    }
}

public enum RemoteFeatureFlag: CaseIterable, Hashable, Decodable {
    case storeCreationCompleteNotification
    case pointOfSale
    case appPasswordsForJetpackSites
    case posLocalCatalogM1
    case wooPosTabletPromoBanner
    case selfDrivenPushNotificationsM1
    case inPersonPaymentsCountryExpansion
    case inPersonPaymentsCountryExpansionEUExtended
    case inPersonPaymentsAustraliaWooPayments
    case pointOfSaleScanToPay
    case pointOfSaleMarkOrderAsPaid
    case wooAIAssistant
    case arParcelFitting
    case qrCodeLogin

    init?(rawValue: String) {
        switch rawValue {
        case "woo_notification_store_creation_ready":
            self = .storeCreationCompleteNotification
        case "woo_pos":
            self = .pointOfSale
        case "woo_app_passwords_for_jetpack_sites":
            self = .appPasswordsForJetpackSites
        case "woo_pos_local_catalog_m1":
            self = .posLocalCatalogM1
        case "woo_pos_tablet_promo_banner":
            self = .wooPosTabletPromoBanner
        case "woo_self_driven_push_notifications_m1":
            self = .selfDrivenPushNotificationsM1
        case "woo_ipp_country_expansion":
            self = .inPersonPaymentsCountryExpansion
        case "woo_ipp_country_expansion_eu_extended":
            self = .inPersonPaymentsCountryExpansionEUExtended
        case "woo_ipp_australia_woopayments":
            self = .inPersonPaymentsAustraliaWooPayments
        case "woo_pos_scan_to_pay":
            self = .pointOfSaleScanToPay
        case "woo_pos_mark_order_as_paid":
            self = .pointOfSaleMarkOrderAsPaid
        case "woo_mobile_ai_assistant":
            self = .wooAIAssistant
        case "woo_ar_parcel_fitting":
            self = .arParcelFitting
        case "woo_qr_code_login":
            self = .qrCodeLogin
        default:
            return nil
        }
    }
}

// MARK: - Constants!
//
private extension FeatureFlagRemote {
    enum Paths {
        static let lookup = "mobile/feature-flags"
    }

    enum ParameterKeys {
        static let platform = "platform"
        static let marketingVersion = "marketing_version"
    }
}
