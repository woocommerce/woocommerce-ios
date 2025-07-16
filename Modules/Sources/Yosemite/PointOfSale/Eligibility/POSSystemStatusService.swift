import Foundation
import Networking
import Storage

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
    private let storageManager: StorageManagerType

    public init(credentials: Credentials?, storageManager: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        self.remote = SystemStatusRemote(network: network)
        self.storageManager = storageManager
    }

    /// Test-friendly initializer that accepts a network implementation.
    init(network: Network, storageManager: StorageManagerType) {
        self.remote = SystemStatusRemote(network: network)
        self.storageManager = storageManager
    }

    @MainActor
    public func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        let mapper = SingleItemMapper<POSPluginEligibilitySystemStatus>(siteID: siteID)
        let systemStatus: POSPluginEligibilitySystemStatus = try await remote.loadSystemStatus(
            for: siteID,
            fields: [.activePlugins, .inactivePlugins, .settings],
            mapper: mapper
        )

        // Upserts all plugins in storage.
        await storageManager.performAndSaveAsync({ [weak self] storage in
            self?.upsertSystemPlugins(siteID: siteID, systemStatus: systemStatus, in: storage)
        })

        // Loads WooCommerce plugin from storage.
        guard let wcPlugin = storageManager.viewStorage.loadSystemPlugin(siteID: siteID, path: Constants.wcPluginPath)?.toReadOnly() else {
            return POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil)
        }

        // Extracts POS feature value from settings response.
        let featureValue = systemStatus.settings.enabledFeatures?.contains(SiteSettingsFeature.pointOfSale.rawValue) == true ? true : nil
        return POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: featureValue)
    }
}

private extension POSSystemStatusService {
    /// Updates or inserts system plugins in storage.
    func upsertSystemPlugins(siteID: Int64, systemStatus: POSPluginEligibilitySystemStatus, in storage: StorageType) {
        // Active and inactive plugins share identical structure, but are stored in separate parts of the remote response
        // (and without an active attribute in the response). So we apply the correct value for active (or not)
        let readonlySystemPlugins: [SystemPlugin] = {
            let activePlugins = systemStatus.activePlugins.map {
                $0.copy(active: true)
            }

            let inactivePlugins = systemStatus.inactivePlugins.map {
                $0.copy(active: false)
            }

            return activePlugins + inactivePlugins
        }()

        let storedPlugins = storage.loadSystemPlugins(siteID: siteID, matching: readonlySystemPlugins.map { $0.name })
        readonlySystemPlugins.forEach { readonlySystemPlugin in
            // Loads or creates new StorageSystemPlugin matching the readonly one.
            let storageSystemPlugin: StorageSystemPlugin = {
                if let systemPlugin = storedPlugins.first(where: { $0.name == readonlySystemPlugin.name }) {
                    return systemPlugin
                }
                return storage.insertNewObject(ofType: StorageSystemPlugin.self)
            }()

            storageSystemPlugin.update(with: readonlySystemPlugin)
        }

        // Removes stale system plugins.
        let currentSystemPlugins = readonlySystemPlugins.map(\.name)
        storage.deleteStaleSystemPlugins(siteID: siteID, currentSystemPlugins: currentSystemPlugins)
    }
}

private extension POSSystemStatusService {
    enum Constants {
        static let wcPluginPath = "woocommerce/woocommerce.php"
    }
}

// MARK: - Network Response Structs

private struct POSPluginEligibilitySystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let inactivePlugins: [SystemPlugin]
    let settings: POSEligibilitySystemStatusSettings

    enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
        case inactivePlugins = "inactive_plugins"
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
