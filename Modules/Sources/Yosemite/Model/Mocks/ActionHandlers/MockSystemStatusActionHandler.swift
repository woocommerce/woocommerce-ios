import Foundation
import Storage
import Networking

struct MockSystemStatusActionHandler: MockActionHandler {
    typealias ActionType = SystemStatusAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .synchronizeSystemInformation(let siteID, let onCompletion):
            synchronizeSystemPlugins(siteID: siteID) { result in
                onCompletion(result.map { SystemInformation(systemPlugins: $0) })
            }
        case .fetchSystemPlugin(let siteID, let systemPluginName, let onCompletion):
            let systemPlugins = objectGraph.systemPlugins(for: siteID)
            let filteredSystemPlugin = systemPlugins.first { $0.name == systemPluginName }
            let matchingPlugin = systemPlugins.first { $0.name == systemPluginName && $0.active } ?? filteredSystemPlugin
            onCompletion(matchingPlugin)
        case .fetchSystemPluginWithPath(let siteID, let pluginPath, let onCompletion):
            let systemPlugins = objectGraph.systemPlugins(for: siteID)
            let matchingPlugin = systemPlugins.first { $0.plugin == pluginPath }
            onCompletion(matchingPlugin)
        case .fetchSystemStatusReport(_, let onCompletion):
            // For now, returns a failure since this mock doesn't implement system status report fetching.
            onCompletion(.failure(NSError(domain: "MockSystemStatusActionHandler", code: 1, userInfo: [:])))
        }
    }

    private func synchronizeSystemPlugins(siteID: Int64, onCompletion: @escaping (Result<[SystemPlugin], Error>) -> Void) {
        let systemPlugins = objectGraph.systemPlugins(for: siteID)

        save(mocks: systemPlugins, as: StorageSystemPlugin.self) { error in
            if let error = error {
                onCompletion(.failure(error))
            } else {
                onCompletion(.success([]))
            }
        }
    }
}
