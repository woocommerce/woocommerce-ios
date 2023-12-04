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
        case .synchronizeSystemInformation(let siteID, let onCompletion):
            synchronizeSystemInformation(siteID: siteID, completionHandler: onCompletion)
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
    func synchronizeSystemInformation(siteID: Int64, completionHandler: @escaping (Result<SystemInformation, Error>) -> Void) {
        remote.loadSystemInformation(for: siteID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let systemInformation):
                self.updateStoreID(siteID: siteID, readonlySystemInformation: systemInformation)
                self.upsertSystemPluginsInBackground(siteID: siteID, readonlySystemInformation: systemInformation) { [weak self] _ in
                    guard let self else { return }
                    let systemPlugins = self.storageManager.viewStorage.loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }
                    completionHandler(.success(.init(storeID: systemInformation.environment?.storeID, systemPlugins: systemPlugins)))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    func fetchSystemStatusReport(siteID: Int64, completionHandler: @escaping (Result<SystemStatus, Error>) -> Void) {
        remote.fetchSystemStatusReport(for: siteID, completion: completionHandler)
    }
}

// MARK: - Storage
//
private extension SystemStatusStore {

    /// Updates or inserts Readonly system information in background.
    /// Triggers `completionHandler` on main thread.
    ///
    func upsertSystemPluginsInBackground(siteID: Int64,
                                         readonlySystemInformation: SystemStatus,
                                         completionHandler: @escaping (Result<Void, Error>) -> Void) {
        let writerStorage = storageManager.writerDerivedStorage
        writerStorage.perform {
            self.upsertSystemPlugins(siteID: siteID, readonlySystemInformation: readonlySystemInformation, in: writerStorage)
        }

        storageManager.saveDerivedType(derivedStorage: writerStorage) {
            DispatchQueue.main.async {
                completionHandler(.success(()))
            }
        }
    }

    /// Updates the store id from the system information.
    ///
    func updateStoreID(siteID: Int64, readonlySystemInformation: SystemStatus) {
        let action = AppSettingsAction.setStoreID(siteID: siteID, id: readonlySystemInformation.environment?.storeID)
        dispatcher.dispatch(action)
    }

    /// Updates or inserts Readonly sistem plugins from the read only system information in specified storage.
    /// Also removes stale plugins that no longer exist in remote plugin list.
    ///
    func upsertSystemPlugins(siteID: Int64, readonlySystemInformation: SystemStatus, in storage: StorageType) {
        /// Active and in-active plugins share identical structure, but are stored in separate parts of the remote response
        /// (and without an active attribute in the response). So... we use the same decoder for active and in-active plugins
        /// and here we apply the correct value for active (or not)
        ///
        let readonlySystemPlugins: [SystemPlugin] = {
            let activePlugins = readonlySystemInformation.activePlugins.map {
                $0.copy(active: true)
            }

            let inactivePlugins = readonlySystemInformation.inactivePlugins.map {
                $0.copy(active: false)
            }

            return activePlugins + inactivePlugins
        }()

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
