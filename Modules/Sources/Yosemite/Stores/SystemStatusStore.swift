import Foundation
import Networking
import Storage

/// Implements `SystemStatusActions` actions
///
public final class SystemStatusStore: Store {
    private let remote: SystemStatusRemote

    override public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
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
    override public func onAction(_ action: Action) {
        guard let action = action as? SystemStatusAction else {
            assertionFailure("SystemPluginStore receives an unsupported action!")
            return
        }

        switch action {
        case .synchronizeSystemInformation(let siteID, let onCompletion):
            synchronizeSystemInformation(siteID: siteID, completionHandler: onCompletion)
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
                self.upsertSystemPluginsInBackground(siteID: siteID, readonlySystemInformation: systemInformation) { [weak self] in
                    guard let self else { return }
                    let systemPlugins = self.storageManager.viewStorage.loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }
                    completionHandler(.success(.init(storeID: systemInformation.environment?.storeID, systemPlugins: systemPlugins)))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    func fetchSystemStatusReport(siteID: Int64, completionHandler: @escaping (Result<SystemStatusReport, Error>) -> Void) {
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
                                         completionHandler: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: readonlySystemInformation.activePlugins, inactivePlugins: readonlySystemInformation.inactivePlugins)
        }, completion: completionHandler, on: .main)
    }

    /// Updates the store id from the system information.
    ///
    func updateStoreID(siteID: Int64, readonlySystemInformation: SystemStatus) {
        let action = AppSettingsAction.setStoreID(siteID: siteID, id: readonlySystemInformation.environment?.storeID)
        dispatcher.dispatch(action)
    }

    func fetchSystemPluginWithPath(siteID: Int64, pluginPath: String, onCompletion: @escaping (SystemPlugin?) -> Void) {
        let viewStorage = storageManager.viewStorage
        onCompletion(viewStorage.loadSystemPlugin(siteID: siteID, path: pluginPath)?.toReadOnly())
    }
}
