import Yosemite

final class MockPluginsService: PluginsServiceProtocol {
    var pluginToReturn: SystemPlugin = .fake()
    var pluginsToReturnForLoadPluginInStorageByPlugin: [Plugin: SystemPlugin?] = [:]

    func waitForPluginInStorage(siteID: Int64, pluginPath: String, isActive: Bool) async -> SystemPlugin {
        pluginToReturn
    }

    func loadPluginInStorage(siteID: Int64, plugin: Yosemite.Plugin, isActive: Bool?) -> SystemPlugin? {
        pluginsToReturnForLoadPluginInStorageByPlugin[plugin] ?? nil
    }
}

extension MockPluginsService {
    func setMockPlugin(_ plugin: Plugin, systemPlugin: SystemPlugin?) {
        pluginsToReturnForLoadPluginInStorageByPlugin[plugin] = systemPlugin
    }
}
