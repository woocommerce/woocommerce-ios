import Foundation
import Yosemite
import class WooFoundation.VersionHelpers

enum PluginCompatibilityResult {
    case compatible
    case incompatible(currentVersion: String, requiredVersion: String)
}

protocol PluginCompatibilityCheckerProtocol {
    func checkCompatibility() async throws -> PluginCompatibilityResult
}

final class PluginCompatibilityChecker: PluginCompatibilityCheckerProtocol {
    private let siteID: Int64
    private let minimumWooCommerceVersion: String
    private let stores: StoresManager

    static let defaultMinimumWooCommerceVersion = "10.4.3"
    private static let wooCommercePluginPath = "woocommerce/woocommerce.php"

    init(siteID: Int64,
         minimumWooCommerceVersion: String = defaultMinimumWooCommerceVersion,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.minimumWooCommerceVersion = minimumWooCommerceVersion
        self.stores = stores
    }

    func checkCompatibility() async throws -> PluginCompatibilityResult {
        let plugin = try await fetchWooCommercePlugin()

        let isSupported = VersionHelpers.isVersionSupported(
            version: plugin.version,
            minimumRequired: minimumWooCommerceVersion
        )

        if isSupported {
            DDLogDebug("📱 Plugin compatibility: WooCommerce \(plugin.version) meets minimum")
            return .compatible
        } else {
            DDLogDebug("📱 Plugin compatibility: WooCommerce \(plugin.version) below minimum")
            return .incompatible(
                currentVersion: plugin.version,
                requiredVersion: minimumWooCommerceVersion
            )
        }
    }
}

private extension PluginCompatibilityChecker {
    func fetchWooCommercePlugin() async throws -> SystemPlugin {
        let systemInfo = try await syncSystemInformation()

        guard let wooPlugin = systemInfo.systemPlugins.first(where: { $0.plugin == Self.wooCommercePluginPath }) else {
            throw PluginCompatibilityError.pluginNotFound
        }

        return wooPlugin
    }

    func syncSystemInformation() async throws -> SystemInformation {
        let stores = self.stores
        let siteID = self.siteID
        return try await withCheckedThrowingContinuation { continuation in
            let action = SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

enum PluginCompatibilityError: Error {
    case pluginNotFound
}
