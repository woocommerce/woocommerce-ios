import Foundation
import Yosemite
import class WooFoundation.VersionHelpers

/// Result of plugin compatibility check
enum PluginCompatibilityResult {
    case compatible
    case incompatible(currentVersion: String, requiredVersion: String)
}

/// Protocol for plugin version checking
protocol PluginCompatibilityCheckerProtocol {
    func checkCompatibility() async throws -> PluginCompatibilityResult
}

/// Checks if the WooCommerce plugin version meets the minimum requirement for push notifications.
/// Uses SystemStatusAction to fetch plugin information.
final class PluginCompatibilityChecker: PluginCompatibilityCheckerProtocol {
    private let siteID: Int64
    private let stores: StoresManager

    /// Hardcoded minimum version requirement for push notifications.
    /// This follows the same pattern as CardPresentPaymentsConfiguration.
    static let minimumWooCommerceVersion = "10.4.3"
    private static let wooCommercePluginPath = "woocommerce/woocommerce.php"

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func checkCompatibility() async throws -> PluginCompatibilityResult {
        let plugin = try await fetchWooCommercePlugin()

        let isSupported = VersionHelpers.isVersionSupported(
            version: plugin.version,
            minimumRequired: Self.minimumWooCommerceVersion
        )

        if isSupported {
            DDLogDebug("📱 Plugin compatibility: WooCommerce \(plugin.version) meets minimum \(Self.minimumWooCommerceVersion)")
            return .compatible
        } else {
            DDLogDebug("📱 Plugin compatibility: WooCommerce \(plugin.version) below minimum \(Self.minimumWooCommerceVersion)")
            return .incompatible(
                currentVersion: plugin.version,
                requiredVersion: Self.minimumWooCommerceVersion
            )
        }
    }
}

// MARK: - Private Helpers
private extension PluginCompatibilityChecker {

    func fetchWooCommercePlugin() async throws -> SystemPlugin {
        // First sync system information to ensure we have the latest plugin data
        let systemInfo = try await syncSystemInformation()

        // Find the WooCommerce plugin
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

// MARK: - Error Types
enum PluginCompatibilityError: LocalizedError {
    case pluginNotFound

    var errorDescription: String? {
        switch self {
        case .pluginNotFound:
            return NSLocalizedString(
                "pluginCompatibilityError.pluginNotFound",
                value: "WooCommerce plugin not found",
                comment: "Error message when WooCommerce plugin cannot be found on the site"
            )
        }
    }
}
