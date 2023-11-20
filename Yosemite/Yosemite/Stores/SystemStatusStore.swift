import Foundation
import Networking
import Storage

/// Implements `SystemStatusActions` actions
///
public final class SystemStatusStore: Store {
    private let remote: SystemStatusRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = SystemStatusRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SystemStatusAction.self)
    }

    /// Receives and executes Actions.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? SystemStatusAction else {
            assertionFailure("SystemPluginStore receives an unsupported action!")
            return
        }

        switch action {
        case .synchronizeSystemPlugins(let siteID, let onCompletion):
            synchronizeSystemPlugins(siteID: siteID, completionHandler: onCompletion)
        case .fetchSystemPlugin(let siteID, let systemPluginName, let onCompletion):
            fetchSystemPlugin(siteID: siteID, systemPluginNameList: [systemPluginName], completionHandler: onCompletion)
        case .fetchSystemPluginListWithNameList(let siteID, let systemPluginNameList, let onCompletion):
            fetchSystemPlugin(siteID: siteID, systemPluginNameList: systemPluginNameList, completionHandler: onCompletion)
        case .fetchSystemPluginWithPath(let siteID, let pluginPath, let onCompletion):
            fetchSystemPluginWithPath(siteID: siteID,
                                      pluginPath: pluginPath,
                                      onCompletion: onCompletion)
        case .fetchSystemStatusReport(let siteID, let onCompletion):
            fetchSystemStatusReport(siteID: siteID, completionHandler: onCompletion)
        }
    }
}

// MARK: - Network request
//
private extension SystemStatusStore {
    func synchronizeSystemPlugins(siteID: Int64, completionHandler: @escaping (Result<[SystemPlugin], Error>) -> Void) {
//        remote.loadSystemPlugins(for: siteID) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let systemPlugins):
//                self.upsertSystemPluginsInBackground(siteID: siteID, readonlySystemPlugins: systemPlugins) { [weak self]_ in
//                    guard let self else { return }
//                    completionHandler(.success(self.storageManager.viewStorage.loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }))
//                }
//            case .failure(let error):
//                completionHandler(.failure(error))
//            }
//        }
    }

    func fetchSystemStatusReport(siteID: Int64, completionHandler: @escaping (Result<SystemStatus, Error>) -> Void) {
        remote.fetchSystemStatusReport(for: siteID, completion: completionHandler)
    }
}

// MARK: - Storage
//
private extension SystemStatusStore {

    /// Updates or inserts Readonly `SystemPlugin` entities in background.
    /// Triggers `completionHandler` on main thread.
    ///
    func upsertSystemPluginsInBackground(siteID: Int64, readonlySystemPlugins: [SystemPlugin], completionHandler: @escaping (Result<Void, Error>) -> Void) {
        let writerStorage = storageManager.writerDerivedStorage
        writerStorage.perform {
            self.upsertSystemPlugins(siteID: siteID, readonlySystemPlugins: readonlySystemPlugins, in: writerStorage)
        }

        storageManager.saveDerivedType(derivedStorage: writerStorage) {
            DispatchQueue.main.async {
                completionHandler(.success(()))
            }
        }
    }

    /// Updates or inserts Readonly `SystemPlugin` entities in specified storage.
    /// Also removes stale plugins that no longer exist in remote plugin list.
    ///
    func upsertSystemPlugins(siteID: Int64, readonlySystemPlugins: [SystemPlugin], in storage: StorageType) {
        readonlySystemPlugins.forEach { readonlySystemPlugin in
            // load or create new StorageSystemPlugin matching the readonly one
            let storageSystemPlugin: StorageSystemPlugin = {
                if let systemPlugin = storage.loadSystemPlugin(siteID: readonlySystemPlugin.siteID, name: readonlySystemPlugin.name) {
                    return systemPlugin
                }
                return storage.insertNewObject(ofType: StorageSystemPlugin.self)
            }()

            storageSystemPlugin.update(with: readonlySystemPlugin)
        }

        // remove stale system plugins
        let currentSystemPlugins = readonlySystemPlugins.map(\.name)
        storage.deleteStaleSystemPlugins(siteID: siteID, currentSystemPlugins: currentSystemPlugins)
    }

    /// Retrieve a `SystemPlugin` entity from storage whose name matches any name from the provided name list.
    /// Useful when a plugin has had multiple names.
    ///
    func fetchSystemPlugin(siteID: Int64, systemPluginNameList: [String], completionHandler: @escaping (SystemPlugin?) -> Void) {
        let viewStorage = storageManager.viewStorage
        for systemPluginName in systemPluginNameList {
            if let systemPlugin = viewStorage.loadSystemPlugin(siteID: siteID, name: systemPluginName)?.toReadOnly() {
                return completionHandler(systemPlugin)
            }
        }
        completionHandler(nil)
    }

    func fetchSystemPluginWithPath(siteID: Int64, pluginPath: String, onCompletion: @escaping (SystemPlugin?) -> Void) {
        let viewStorage = storageManager.viewStorage
        onCompletion(viewStorage.loadSystemPlugin(siteID: siteID, path: pluginPath)?.toReadOnly())
    }
}
