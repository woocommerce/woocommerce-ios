import CocoaLumberjackSwift
import Foundation
import Yosemite
import class WooFoundation.VersionHelpers

enum PluginVersionResult {
    case compatible
    case incompatible(currentVersion: String, requiredVersion: String)
}

protocol PluginVersionCheckerProtocol {
    func checkCompatibility() async throws -> PluginVersionResult
}

final class PluginVersionChecker: PluginVersionCheckerProtocol {
    private let siteID: Int64
    private let pluginPath: String
    private let minimumVersion: String
    private let stores: StoresManager

    init(siteID: Int64,
         pluginPath: String,
         minimumVersion: String,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.pluginPath = pluginPath
        self.minimumVersion = minimumVersion
        self.stores = stores
    }

    func checkCompatibility() async throws -> PluginVersionResult {
        let plugin = try await fetchPlugin()

        let isSupported = VersionHelpers.isVersionSupported(
            version: plugin.version,
            minimumRequired: minimumVersion
        )

        if isSupported {
            DDLogDebug("Plugin compatibility: \(pluginPath) \(plugin.version) meets minimum \(minimumVersion)")
            return .compatible
        } else {
            DDLogDebug("Plugin compatibility: \(pluginPath) \(plugin.version) below minimum \(minimumVersion)")
            return .incompatible(
                currentVersion: plugin.version,
                requiredVersion: minimumVersion
            )
        }
    }
}

private extension PluginVersionChecker {
    func fetchPlugin() async throws -> SystemPlugin {
        let systemInfo = try await syncSystemInformation()

        guard let plugin = systemInfo.systemPlugins.first(where: { $0.plugin == pluginPath }) else {
            throw PluginVersionError.pluginNotFound
        }

        return plugin
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

enum PluginVersionError: Error {
    case pluginNotFound
}
