import Foundation

public protocol ActivePluginVersionsProviding {
    @MainActor
    func activePluginVersions(siteID: Int64?) -> [String: String]
}

public final class WooCommerceActivePluginVersionsProvider: ActivePluginVersionsProviding {
    public static let wooCommercePluginPath = "woocommerce/woocommerce.php"

    private let pluginsService: PluginsServiceProtocol

    public init(pluginsService: PluginsServiceProtocol) {
        self.pluginsService = pluginsService
    }

    @MainActor
    public func activePluginVersions(siteID: Int64?) -> [String: String] {
        guard let siteID,
              let plugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: true) else {
            return [:]
        }

        return Self.activePluginVersions(from: [plugin])
    }

    public static func activePluginVersions(from systemPlugins: [SystemPlugin]) -> [String: String] {
        guard let plugin = systemPlugins.first(where: { plugin in
            plugin.plugin == wooCommercePluginPath && plugin.active && plugin.version.isEmpty == false
        }) else {
            return [:]
        }

        return [wooCommercePluginPath: plugin.version]
    }
}
