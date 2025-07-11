import Foundation
import Networking

public protocol POSSystemStatusServiceProtocol {
    /// Loads WooCommerce plugin and POS feature switch value remotely for eligibility checks.
    /// - Parameter siteID: The site ID to fetch information for.
    /// - Returns: POSPluginAndFeatureInfo containing plugin and feature data.
    /// - Throws: Network or parsing errors.
    func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo
}

/// Contains WooCommerce plugin information and POS feature switch value.
public struct POSPluginAndFeatureInfo {
    public let wcPlugin: SystemPlugin?
    public let featureValue: Bool?

    public init(wcPlugin: SystemPlugin?, featureValue: Bool?) {
        self.wcPlugin = wcPlugin
        self.featureValue = featureValue
    }
}

/// Service for fetching POS-related system status information.
public final class POSSystemStatusService: POSSystemStatusServiceProtocol {
    private let remote: SystemStatusRemote

    public init(credentials: Credentials?) {
        let network = AlamofireNetwork(credentials: credentials)
        remote = SystemStatusRemote(network: network)
    }

    /// Test-friendly initializer that accepts a network implementation.
    init(network: Network) {
        remote = SystemStatusRemote(network: network)
    }

    public func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        let mapper = SingleItemMapper<POSPluginEligibilitySystemStatus>(siteID: siteID)
        let systemStatus: POSPluginEligibilitySystemStatus = try await remote.loadSystemStatus(
            for: siteID,
            fields: [.activePlugins, .settings],
            mapper: mapper
        )

        // Finds WooCommerce plugin from active plugins response.
        guard let wcPlugin = systemStatus.activePlugins.first(where: { $0.plugin == Constants.wcPluginPath }) else {
            return POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil)
        }

        // Extracts POS feature value from settings response.
        let featureValue = systemStatus.settings.enabledFeatures?.contains(SiteSettingsFeature.pointOfSale.rawValue) == true ? true : nil
        return POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: featureValue)
    }
}

private extension POSSystemStatusService {
    enum Constants {
        static let wcPluginPath = "woocommerce/woocommerce.php"
    }
}

// MARK: - Errors

public enum POSSystemStatusServiceError: Error {
    case wooCommercePluginNotFound
}

// MARK: - Network Response Structs

private struct POSPluginEligibilitySystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let settings: POSEligibilitySystemStatusSettings

    enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
        case settings
    }
}

private struct POSEligibilitySystemStatusSettings: Decodable {
    // As `settings.enable_features` was introduced in WC version 9.9.0, this field is optional.
    // Ref: https://github.com/woocommerce/woocommerce/pull/57168
    let enabledFeatures: [String]?

    enum CodingKeys: String, CodingKey {
        case enabledFeatures = "enabled_features"
    }
}
