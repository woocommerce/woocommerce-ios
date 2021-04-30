import Foundation
import Networking
import Storage

/// Implements actions from `AddOnGroupAction`
///
public final class AddOnGroupStore: Store {

    /// Remote source
    ///
    private let remote: AddOnGroupRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = AddOnGroupRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AddOnGroupAction.self)
    }

    /// Receives and executes actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AddOnGroupAction else {
            assertionFailure("ProductCategoryStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizeAddOnGroups(siteID, onCompletion):
            synchronizeAddOnGroups(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: Services
private extension AddOnGroupStore {
    /// Downloads and stores all add-on groups for a given `siteID`.
    ///
    func synchronizeAddOnGroups(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadAddOnGroups(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let groups):
                self?.upsertAddOnGroupsInBackground(readOnlyAddOnGroups: groups, onCompletion: onCompletion)
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: Storage
private extension AddOnGroupStore {
    /// Updates (OR Inserts) the provided ReadOnly `AddOnGroups` entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertAddOnGroupsInBackground(readOnlyAddOnGroups: [AddOnGroup], onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let derivedStorage = storageManager.writerDerivedStorage
        derivedStorage.perform {
            self.upsertAddOnGroups(readOnlyAddOnGroups: readOnlyAddOnGroups, in: derivedStorage)
        }
        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async {
                onCompletion(.success(()))
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly `AddOnGroups` entities into the Storage Layer.
    ///
    func upsertAddOnGroups(readOnlyAddOnGroups: [AddOnGroup], in storage: StorageType) {
        // TODO: Add implementation
    }
}
