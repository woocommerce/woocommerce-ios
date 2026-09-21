import Foundation
@testable import Yosemite

final class MockPluginsService: PluginsServiceProtocol {
    var pluginsToReturnByPlugin: [Plugin: SystemPlugin] = [:]

    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        pluginsToReturnByPlugin[plugin]
    }
}
