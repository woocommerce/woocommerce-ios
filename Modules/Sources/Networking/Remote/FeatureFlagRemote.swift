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
