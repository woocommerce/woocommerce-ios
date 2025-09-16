import Foundation
import Networking
import Storage
import struct Combine.AnyPublisher

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
    private let pluginsService: PluginsServiceProtocol

    public init(credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                storageManager: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.remote = SystemStatusRemote(network: network)
        self.storageManager = storageManager
        self.pluginsService = PluginsService(storageManager: storageManager)
    }

    /// Test-friendly initializer that accepts a network implementation.
    init(network: Network, storageManager: StorageManagerType) {
        self.remote = SystemStatusRemote(network: network)
        self.storageManager = storageManager
        self.pluginsService = PluginsService(storageManager: storageManager)
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
        await storageManager.performAndSaveAsync({ storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: systemStatus.activePlugins, inactivePlugins: systemStatus.inactivePlugins)
        })

        // Loads WooCommerce plugin from storage.
        guard let wcPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: true) else {
            return POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil)
        }

        // Extracts POS feature value from settings response.
        let featureValue = systemStatus.settings.enabledFeatures?.contains(SiteSettingsFeature.pointOfSale.rawValue) == true ? true : nil
        return POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: featureValue)
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
