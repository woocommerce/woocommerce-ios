import Yosemite

final class MockPluginsService: PluginsServiceProtocol {
    var pluginToReturn: SystemPlugin = .fake()
    var pluginToReturnForLoadPluginInStorage: SystemPlugin?

    func waitForPluginInStorage(siteID: Int64, pluginPath: String, isActive: Bool) async -> SystemPlugin {
        pluginToReturn
    }

    func loadPluginInStorage(siteID: Int64, plugin: Yosemite.Plugin, isActive: Bool?) -> SystemPlugin? {
        pluginToReturnForLoadPluginInStorage
    }
}
