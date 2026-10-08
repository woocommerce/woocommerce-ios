import Foundation
import Synchronization
@testable import Yosemite

final class MockPluginsService: PluginsServiceProtocol, Sendable {
    private struct State {
        var pluginsToReturnByPlugin: [Plugin: SystemPlugin] = [:]
    }

    private let state = Mutex(State())

    var pluginsToReturnByPlugin: [Plugin: SystemPlugin] {
        get { state.withLock { $0.pluginsToReturnByPlugin } }
        set { state.withLock { $0.pluginsToReturnByPlugin = newValue } }
    }

    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        pluginsToReturnByPlugin[plugin]
    }
}
