import Foundation

public protocol SystemStatusServiceProtocol {
    // TODO: rename to `synchronizeSystemPlugins`
    func synchronizeSystemInformation(siteID: Int64) async throws -> [SystemPlugin]
    func fetchSystemPluginWithPath(siteID: Int64, pluginPath: String) async -> SystemPlugin?
}

public struct SystemStatusService: SystemStatusServiceProtocol {
    let stores: StoresManager

    public init(stores: StoresManager) {
        self.stores = stores
    }

    @MainActor
    public func synchronizeSystemInformation(siteID: Int64) async throws -> [SystemPlugin] {
        try await withCheckedThrowingContinuation { continuation in
            let action = SystemStatusAction.synchronizeSystemPlugins(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    public func fetchSystemPluginWithPath(siteID: Int64, pluginPath: String) async -> SystemPlugin? {
        await withCheckedContinuation({ continuation in
            let action = SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID,
                                                                      pluginPath: pluginPath) { plugin in
                continuation.resume(returning: plugin)
            }
            stores.dispatch(action)
        })
    }
}
